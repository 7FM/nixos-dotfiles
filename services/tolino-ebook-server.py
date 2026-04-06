#!/usr/bin/env python3
"""Tolino Ebook Server — serves recommendations and ebook downloads."""

import argparse
import hashlib
import hmac
import json
import mimetypes
import os
import posixpath
import re
import secrets
import urllib.parse
import zipfile
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from xml.etree import ElementTree

import html as html_mod
import itertools
import math
import time
import random
import sqlite3
import string
import tempfile

EBOOK_EXTENSIONS = {".epub", ".pdf"}
BOOKS_PER_PAGE = 6

OPF_NS = "http://www.idpf.org/2007/opf"
DC_NS = "http://purl.org/dc/elements/1.1/"
CONTAINER_NS = "urn:oasis:names:tc:opendocument:xmlns:container"


def parse_epub_metadata(epub_path):
    """Extract title, author, and cover image bytes from an EPUB file."""
    title = None
    author = None
    cover_data = None
    cover_media_type = None

    try:
        with zipfile.ZipFile(epub_path, "r") as zf:
            # Find OPF file via container.xml
            container_xml = zf.read("META-INF/container.xml")
            container = ElementTree.fromstring(container_xml)
            rootfile = container.find(f".//{{{CONTAINER_NS}}}rootfile")
            if rootfile is None:
                return title, author, cover_data, cover_media_type
            opf_path = rootfile.get("full-path")
            if opf_path is None:
                return title, author, cover_data, cover_media_type

            opf_xml = zf.read(opf_path)
            opf = ElementTree.fromstring(opf_xml)
            opf_dir = posixpath.dirname(opf_path)

            # Extract title and author
            title_el = opf.find(f".//{{{DC_NS}}}title")
            if title_el is not None and title_el.text:
                title = title_el.text.strip()

            creator_el = opf.find(f".//{{{DC_NS}}}creator")
            if creator_el is not None and creator_el.text:
                author = creator_el.text.strip()

            # Find cover image
            cover_id = None
            for meta in opf.findall(f".//{{{OPF_NS}}}meta"):
                if meta.get("name") == "cover":
                    cover_id = meta.get("content")
                    break

            if cover_id:
                manifest = opf.find(f"{{{OPF_NS}}}manifest")
                if manifest is not None:
                    for item in manifest.findall(f"{{{OPF_NS}}}item"):
                        if item.get("id") == cover_id:
                            href = item.get("href")
                            cover_media_type = item.get("media-type")
                            if href:
                                cover_zip_path = posixpath.join(opf_dir, href) if opf_dir else href
                                # Normalize path (handle ../ etc)
                                cover_zip_path = posixpath.normpath(cover_zip_path)
                                try:
                                    cover_data = zf.read(cover_zip_path)
                                except KeyError:
                                    # Try URL-decoded version
                                    decoded = urllib.parse.unquote(cover_zip_path)
                                    try:
                                        cover_data = zf.read(decoded)
                                    except KeyError:
                                        cover_data = None
                            break

            # Fallback: look for cover in manifest items by properties attribute (EPUB3)
            if cover_data is None:
                manifest = opf.find(f"{{{OPF_NS}}}manifest")
                if manifest is not None:
                    for item in manifest.findall(f"{{{OPF_NS}}}item"):
                        props = item.get("properties", "")
                        if "cover-image" in props:
                            href = item.get("href")
                            cover_media_type = item.get("media-type")
                            if href:
                                cover_zip_path = posixpath.join(opf_dir, href) if opf_dir else href
                                cover_zip_path = posixpath.normpath(cover_zip_path)
                                try:
                                    cover_data = zf.read(cover_zip_path)
                                except KeyError:
                                    decoded = urllib.parse.unquote(cover_zip_path)
                                    try:
                                        cover_data = zf.read(decoded)
                                    except KeyError:
                                        cover_data = None
                            break
    except (zipfile.BadZipFile, KeyError, ElementTree.ParseError):
        pass

    return title, author, cover_data, cover_media_type


def title_from_filename(filename):
    """Derive a display title from a filename."""
    stem = Path(filename).stem
    # Replace underscores and hyphens with spaces
    stem = stem.replace("_", " ").replace("-", " ")
    # Collapse multiple spaces
    stem = re.sub(r"\s+", " ", stem).strip()
    return stem


def get_ebooks(ebook_dir):
    """List ebook files sorted by modification time (newest first)."""
    ebooks = []
    try:
        for entry in os.scandir(ebook_dir):
            if entry.is_file() and Path(entry.name).suffix.lower() in EBOOK_EXTENSIONS:
                ebooks.append((entry.name, entry.stat().st_mtime))
    except OSError:
        pass
    ebooks.sort(key=lambda x: x[1], reverse=True)
    return [name for name, _ in ebooks]


def ensure_cover_cached(filename, ebook_dir, cover_cache_dir):
    """Extract and cache cover image from EPUB. Returns (cache_path, media_type) or (None, None)."""
    ext = Path(filename).suffix.lower()
    if ext != ".epub":
        return None, None

    epub_path = os.path.join(ebook_dir, filename)
    # Check if cached
    for candidate_ext in (".jpg", ".jpeg", ".png", ".gif"):
        cached = os.path.join(cover_cache_dir, filename + candidate_ext)
        if os.path.exists(cached):
            # Verify cache is newer than epub
            if os.path.getmtime(cached) >= os.path.getmtime(epub_path):
                mt = mimetypes.guess_type(cached)[0] or "image/jpeg"
                return cached, mt

    # Extract
    _, _, cover_data, cover_media_type = parse_epub_metadata(epub_path)
    if cover_data is None:
        return None, None

    # Determine extension from media type
    ext_map = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/gif": ".gif",
    }
    cover_ext = ext_map.get(cover_media_type, ".jpg")
    cached_path = os.path.join(cover_cache_dir, filename + cover_ext)

    os.makedirs(cover_cache_dir, exist_ok=True)
    with open(cached_path, "wb") as f:
        f.write(cover_data)

    return cached_path, cover_media_type or "image/jpeg"


def build_recommendation(filename, ebook_dir, base_url, cover_cache_dir, auth_token):
    """Build a BeanRecommendation dict for one ebook."""
    ext = Path(filename).suffix.lower()
    encoded_name = urllib.parse.quote(filename, safe="")
    token_qs = f"?token={urllib.parse.quote(auth_token, safe='')}" if auth_token else ""

    title = None
    author = None

    if ext == ".epub":
        epub_path = os.path.join(ebook_dir, filename)
        title, author, _, _ = parse_epub_metadata(epub_path)

    if not title:
        title = title_from_filename(filename)
    if not author:
        author = ""

    pub_id = hashlib.sha256(filename.encode()).hexdigest()[:16]
    fmt = "EPUB" if ext == ".epub" else "PDF"

    cover_url = ""
    cover_path, _ = ensure_cover_cached(filename, ebook_dir, cover_cache_dir)
    if cover_path:
        cover_url = f"{base_url}/cover/{encoded_name}{token_qs}"

    return {
        "publicationId": pub_id,
        "title": title,
        "author": author,
        "cover_url": cover_url,
        "shop_url": f"{base_url}/shop/{encoded_name}.detail{token_qs}",
        "publicationType": "EBOOK",
        "format": fmt,
    }


SHOP_CSS = """\
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: serif; background: #fff; color: #000; max-width: 567px; margin: 0 auto; padding: 8px; }
h1 { font-size: 18px; text-align: center; padding: 6px 0; border-bottom: 2px solid #000; margin-bottom: 8px; }
.nav { display: flex; justify-content: space-between; align-items: center; padding: 4px 0; margin-bottom: 8px; }
.nav a { text-decoration: none; color: #000; font-size: 20px; font-weight: bold; padding: 4px 12px; border: 2px solid #000; }
.nav a.disabled { color: #ccc; border-color: #ccc; pointer-events: none; }
.nav span { font-size: 14px; }
.grid { display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; }
.book { width: 170px; text-align: center; }
.book a { text-decoration: none; color: #000; display: block; }
.book img { width: 150px; height: 210px; object-fit: cover; border: 1px solid #000; }
.book .no-cover { width: 150px; height: 210px; border: 1px solid #000; display: flex; align-items: center; justify-content: center; font-size: 13px; padding: 8px; background: #f0f0f0; }
.book .title { font-size: 13px; font-weight: bold; margin-top: 4px; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
.book .author { font-size: 11px; color: #555; }
.detail { text-align: center; padding: 8px 0; }
.detail img { max-width: 240px; max-height: 340px; border: 1px solid #000; }
.detail .no-cover { width: 240px; height: 340px; border: 1px solid #000; display: flex; align-items: center; justify-content: center; font-size: 16px; padding: 16px; margin: 0 auto; background: #f0f0f0; }
.detail h2 { font-size: 18px; margin: 10px 0 4px; }
.detail .author { font-size: 14px; color: #555; margin-bottom: 12px; }
.detail .btn { display: inline-block; padding: 10px 24px; border: 2px solid #000; text-decoration: none; color: #000; font-size: 16px; font-weight: bold; margin: 8px 4px; }
.detail .back { font-size: 14px; margin-top: 12px; }
.detail .back a { color: #000; }
"""


def render_shop_index(ebooks, ebook_dir, cover_cache_dir, base_url, auth_token, page, total_pages):
    """Render the paginated shop index page."""
    esc = html_mod.escape
    token_qs = f"?token={urllib.parse.quote(auth_token, safe='')}" if auth_token else ""

    books_html = []
    for filename in ebooks:
        encoded = urllib.parse.quote(filename, safe="")
        title, author = None, None
        if Path(filename).suffix.lower() == ".epub":
            epub_path = os.path.join(ebook_dir, filename)
            title, author, _, _ = parse_epub_metadata(epub_path)
        if not title:
            title = title_from_filename(filename)
        if not author:
            author = ""

        cover_path, _ = ensure_cover_cached(filename, ebook_dir, cover_cache_dir)
        if cover_path:
            cover_html = f'<img src="{esc(base_url)}/cover/{esc(encoded)}{esc(token_qs)}" alt="{esc(title)}">'
        else:
            cover_html = f'<div class="no-cover">{esc(title)}</div>'

        books_html.append(
            f'<div class="book"><a href="{esc(base_url)}/shop/{esc(encoded)}.detail{esc(token_qs)}">'
            f'{cover_html}<div class="title">{esc(title)}</div>'
            f'<div class="author">{esc(author)}</div></a></div>'
        )

    prev_cls = ' class="disabled"' if page <= 1 else ""
    next_cls = ' class="disabled"' if page >= total_pages else ""
    page_sep = "&" if token_qs else "?"
    prev_href = f"{base_url}/shop{token_qs}{page_sep}page={page - 1}" if page > 1 else "#"
    next_href = f"{base_url}/shop{token_qs}{page_sep}page={page + 1}" if page < total_pages else "#"

    return f"""\
<!DOCTYPE html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=567">
<title>Library</title>
<link rel="stylesheet" href="{esc(base_url)}/shop/static/style.css{esc(token_qs)}">
<script>function android_init(){{}}</script>
</head><body>
<h1>Library</h1>
<div class="nav">
<a href="{esc(prev_href)}"{prev_cls}>&lt; Prev</a>
<span>Page {page} / {total_pages}</span>
<a href="{esc(next_href)}"{next_cls}>Next &gt;</a>
</div>
<div class="grid">{"".join(books_html)}</div>
</body></html>"""


def render_shop_detail(filename, ebook_dir, cover_cache_dir, base_url, auth_token):
    """Render a single book detail page."""
    esc = html_mod.escape
    encoded = urllib.parse.quote(filename, safe="")
    token_qs = f"?token={urllib.parse.quote(auth_token, safe='')}" if auth_token else ""

    title, author = None, None
    if Path(filename).suffix.lower() == ".epub":
        epub_path = os.path.join(ebook_dir, filename)
        title, author, _, _ = parse_epub_metadata(epub_path)
    if not title:
        title = title_from_filename(filename)
    if not author:
        author = ""

    cover_path, _ = ensure_cover_cached(filename, ebook_dir, cover_cache_dir)
    if cover_path:
        cover_html = f'<img src="{esc(base_url)}/cover/{esc(encoded)}{esc(token_qs)}" alt="{esc(title)}">'
    else:
        cover_html = f'<div class="no-cover">{esc(title)}</div>'

    return f"""\
<!DOCTYPE html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=567">
<title>{esc(title)}</title>
<link rel="stylesheet" href="{esc(base_url)}/shop/static/style.css{esc(token_qs)}">
<script>function android_init(){{}}</script>
</head><body>
<div class="detail">
{cover_html}
<h2>{esc(title)}</h2>
<div class="author">{esc(author)}</div>
<a class="btn" href="{esc(base_url)}/download/{esc(encoded)}{esc(token_qs)}">Download</a>
<div class="back"><a href="{esc(base_url)}/shop{esc(token_qs)}">&lt; Back to Library</a></div>
</div>
</body></html>"""


def init_vocab_db(db_path):
    """Create vocab SQLite database if it doesn't exist."""
    conn = sqlite3.connect(db_path)
    conn.execute("""CREATE TABLE IF NOT EXISTS vocab (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT, definition TEXT,
        source_lang TEXT, target_lang TEXT,
        book TEXT, timestamp INTEGER,
        created_at REAL DEFAULT (strftime('%s','now'))
    )""")
    conn.commit()
    conn.close()


def _base91(num):
    table = string.ascii_letters + string.digits + '!#$%&()*+,-./:;<=>?@[]^_`{|}~'
    buf = ''
    while num:
        num, mod = divmod(num, len(table))
        buf = table[mod] + buf
    return buf or 'a'


def _field_checksum(text):
    return int(hashlib.sha1(text.encode('utf-8')).hexdigest()[:8], 16)


def generate_apkg(vocab_rows):
    """Generate an .apkg file in memory from vocab rows.
    Each row: (word, definition, source_lang, target_lang, book, timestamp).
    Returns bytes of the ZIP file.
    """
    import io as _io

    ts = time.time()
    model_id = int(ts * 1000)
    deck_id = model_id + 1
    id_counter = itertools.count(int(ts * 1000) + 2)

    model = {
        "id": model_id, "name": "Tolino Vocabulary", "type": 0,
        "mod": int(ts), "usn": -1, "sortf": 0, "did": deck_id,
        "css": ".card { font-family: arial; font-size: 20px; text-align: center; }\n"
               ".lang { font-size: 12px; color: #888; margin-top: 8px; }",
        "latexPre": "", "latexPost": "", "latexsvg": False,
        "req": [[0, "any", [0]]], "tags": [], "vers": [],
        "flds": [
            {"name": "Front", "ord": 0, "sticky": False, "rtl": False, "font": "Arial", "size": 20, "media": []},
            {"name": "Back", "ord": 1, "sticky": False, "rtl": False, "font": "Arial", "size": 20, "media": []},
        ],
        "tmpls": [{
            "name": "Card 1", "ord": 0,
            "qfmt": "{{Front}}",
            "afmt": "{{FrontSide}}<hr id=answer>{{Back}}",
            "bqfmt": "", "bafmt": "", "did": None, "bfont": "", "bsize": 0,
        }],
    }

    deck = {
        "id": deck_id, "name": "Tolino Vocabulary", "desc": "",
        "mod": int(ts), "usn": -1, "collapsed": False, "browserCollapsed": False,
        "conf": 1, "dyn": 0, "extendNew": 10, "extendRev": 50,
        "lrnToday": [0, 0], "revToday": [0, 0], "newToday": [0, 0], "timeToday": [0, 0],
    }

    dconf = {"1": {
        "id": 1, "name": "Default", "mod": 0, "usn": 0, "maxTaken": 60,
        "autoplay": True, "timer": 0, "replayq": True, "dyn": False,
        "new": {"bury": True, "delays": [1, 10], "initialFactor": 2500, "ints": [1, 4, 7], "order": 1, "perDay": 20, "separate": True},
        "rev": {"bury": True, "ease4": 1.3, "fuzz": 0.05, "ivlFct": 1, "maxIvl": 36500, "minSpace": 1, "perDay": 100},
        "lapse": {"delays": [10], "leechAction": 0, "leechFails": 8, "minInt": 1, "mult": 0},
    }}

    conf = {
        "activeDecks": [deck_id], "addToCur": True, "collapseTime": 1200,
        "curDeck": deck_id, "curModel": str(model_id), "dueCounts": True,
        "estTimes": True, "newBury": True, "newSpread": 0, "nextPos": 1,
        "sortBackwards": False, "sortType": "noteFld", "timeLim": 0,
    }

    schema_sql = """
    CREATE TABLE col (id integer primary key, crt integer not null, mod integer not null,
        scm integer not null, ver integer not null, dty integer not null, usn integer not null,
        ls integer not null, conf text not null, models text not null, decks text not null,
        dconf text not null, tags text not null);
    CREATE TABLE notes (id integer primary key, guid text not null, mid integer not null,
        mod integer not null, usn integer not null, tags text not null, flds text not null,
        sfld integer not null, csum integer not null, flags integer not null, data text not null);
    CREATE TABLE cards (id integer primary key, nid integer not null, did integer not null,
        ord integer not null, mod integer not null, usn integer not null, type integer not null,
        queue integer not null, due integer not null, ivl integer not null, factor integer not null,
        reps integer not null, lapses integer not null, left integer not null, odue integer not null,
        odid integer not null, flags integer not null, data text not null);
    CREATE TABLE revlog (id integer primary key, cid integer not null, usn integer not null,
        ease integer not null, ivl integer not null, lastIvl integer not null, factor integer not null,
        time integer not null, type integer not null);
    CREATE TABLE graves (usn integer not null, oid integer not null, type integer not null);
    CREATE INDEX ix_notes_usn ON notes (usn);
    CREATE INDEX ix_cards_usn ON cards (usn);
    CREATE INDEX ix_revlog_usn ON revlog (usn);
    CREATE INDEX ix_cards_nid ON cards (nid);
    CREATE INDEX ix_cards_sched ON cards (did, queue, due);
    CREATE INDEX ix_revlog_cid ON revlog (cid);
    CREATE INDEX ix_notes_csum ON notes (csum);
    """

    fd, db_path = tempfile.mkstemp(suffix='.anki2')
    os.close(fd)
    try:
        conn = sqlite3.connect(db_path)
        c = conn.cursor()
        c.executescript(schema_sql)
        c.execute('INSERT INTO col VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',
                  (None, int(ts), int(ts * 1000), int(ts * 1000), 11, 0, 0, 0,
                   json.dumps(conf), json.dumps({str(model_id): model}),
                   json.dumps({str(deck_id): deck}), json.dumps(dconf), '{}'))

        for due_pos, (word, definition, src, tgt, book, tstamp) in enumerate(vocab_rows):
            front = f"{word}<div class='lang'>{src}</div>" if src else word
            back = f"{definition}<div class='lang'>{tgt}</div>" if tgt else (definition or "")
            nid = next(id_counter)
            guid = _base91(random.randint(0, 2**64 - 1))
            c.execute('INSERT INTO notes VALUES(?,?,?,?,?,?,?,?,?,?,?)',
                      (nid, guid, model_id, int(ts), -1, '',
                       front + '\x1f' + back, word, _field_checksum(word), 0, ''))
            c.execute('INSERT INTO cards VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                      (next(id_counter), nid, deck_id, 0, int(ts), -1,
                       0, 0, due_pos, 0, 0, 0, 0, 0, 0, 0, 0, ''))

        conn.commit()
        conn.close()

        buf = _io.BytesIO()
        with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
            zf.write(db_path, 'collection.anki2')
            zf.writestr('media', '{}')
        return buf.getvalue()
    finally:
        os.unlink(db_path)


class EbookHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Use simple print for systemd journal
        print(f"{self.client_address[0]} - {format % args}")

    def check_auth(self, query):
        """Validate token from query parameter or Authorization header."""
        expected = self.server.auth_token
        if not expected:
            return True

        # Check query parameter
        token = query.get("token", [None])[0]
        if token and hmac.compare_digest(token, expected):
            return True

        # Check Authorization header
        auth = self.headers.get("Authorization", "")
        if auth.startswith("Bearer ") and hmac.compare_digest(auth[7:], expected):
            return True

        return False

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        query = urllib.parse.parse_qs(parsed.query)

        if not self.check_auth(query):
            self.send_error(403, "Invalid or missing token")
            return

        if path == "/recommendations":
            self.handle_recommendations(query)
        elif path == "/sync/vocab/anki":
            self.handle_vocab_anki()
        elif path == "/sync/list.txt":
            self.handle_sync_list()
        elif path.startswith("/download/"):
            filename = urllib.parse.unquote(path[len("/download/"):])
            self.handle_download(filename)
        elif path.startswith("/cover/"):
            filename = urllib.parse.unquote(path[len("/cover/"):])
            self.handle_cover(filename)
        elif path == "/shop/static/style.css":
            self.handle_shop_css()
        elif path == "/shop" or path == "":
            self.handle_shop_index(query)
        elif path.startswith("/shop/") and path.endswith(".detail"):
            filename = urllib.parse.unquote(path[len("/shop/"):-len(".detail")])
            self.handle_shop_detail(filename)
        else:
            self.send_error(404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        query = urllib.parse.parse_qs(parsed.query)

        if not self.check_auth(query):
            self.send_error(403, "Invalid or missing token")
            return

        if path == "/sync/vocab":
            self.handle_vocab_post()
        else:
            self.send_error(404)

    def handle_vocab_post(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            entries = json.loads(body)
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON")
            return

        if not isinstance(entries, list):
            entries = [entries]

        db_path = self.server.vocab_db_path
        conn = sqlite3.connect(db_path)
        for e in entries:
            conn.execute(
                "INSERT INTO vocab (word, definition, source_lang, target_lang, book, timestamp) VALUES (?,?,?,?,?,?)",
                (e.get("word", ""), e.get("definition", ""),
                 e.get("sourceLanguage", ""), e.get("targetLanguage", ""),
                 e.get("book", ""), e.get("timestamp", 0)))
        conn.commit()
        conn.close()

        data = json.dumps({"ok": True, "count": len(entries)}).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def handle_vocab_anki(self):
        db_path = self.server.vocab_db_path
        conn = sqlite3.connect(db_path)
        rows = conn.execute(
            "SELECT word, definition, source_lang, target_lang, book, timestamp "
            "FROM vocab ORDER BY timestamp DESC").fetchall()
        conn.close()

        if not rows:
            self.send_error(404, "No vocabulary entries")
            return

        data = generate_apkg(rows)
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Disposition", 'attachment; filename="tolino-vocab.apkg"')
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def handle_recommendations(self, query):
        count = int(query.get("count", ["12"])[0])
        ebook_dir = self.server.ebook_dir
        base_url = self.server.base_url
        cover_cache_dir = self.server.cover_cache_dir
        auth_token = self.server.auth_token

        ebooks = get_ebooks(ebook_dir)[:count]
        recommendations = [
            build_recommendation(f, ebook_dir, base_url, cover_cache_dir, auth_token)
            for f in ebooks
        ]

        data = json.dumps(recommendations, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def handle_sync_list(self):
        ebook_dir = self.server.ebook_dir
        base_url = self.server.sync_base_url
        auth_token = self.server.auth_token
        token_qs = f"?token={urllib.parse.quote(auth_token, safe='')}" if auth_token else ""

        ebooks = get_ebooks(ebook_dir)
        lines = [
            f"{base_url}/download/{urllib.parse.quote(f, safe='')}{token_qs}"
            for f in ebooks
        ]
        data = ("\n".join(lines) + "\n").encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def handle_download(self, filename):
        if "/" in filename or filename.startswith("."):
            self.send_error(403)
            return

        filepath = os.path.join(self.server.ebook_dir, filename)
        if not os.path.isfile(filepath):
            self.send_error(404)
            return

        content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        file_size = os.path.getsize(filepath)

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(file_size))
        self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
        self.end_headers()

        with open(filepath, "rb") as f:
            while chunk := f.read(65536):
                self.wfile.write(chunk)

    def handle_cover(self, filename):
        if "/" in filename or filename.startswith("."):
            self.send_error(403)
            return

        # Check the ebook actually exists
        epub_path = os.path.join(self.server.ebook_dir, filename)
        if not os.path.isfile(epub_path):
            self.send_error(404)
            return

        cover_path, media_type = ensure_cover_cached(
            filename, self.server.ebook_dir, self.server.cover_cache_dir
        )
        if cover_path is None:
            self.send_error(404)
            return

        file_size = os.path.getsize(cover_path)
        self.send_response(200)
        self.send_header("Content-Type", media_type)
        self.send_header("Content-Length", str(file_size))
        self.send_header("Cache-Control", "public, max-age=86400")
        self.end_headers()

        with open(cover_path, "rb") as f:
            while chunk := f.read(65536):
                self.wfile.write(chunk)

    def handle_shop_css(self):
        data = SHOP_CSS.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/css; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "public, max-age=3600")
        self.end_headers()
        self.wfile.write(data)

    def handle_shop_index(self, query):
        page = max(1, int(query.get("page", ["1"])[0]))
        ebook_dir = self.server.ebook_dir
        all_ebooks = get_ebooks(ebook_dir)
        total_pages = max(1, math.ceil(len(all_ebooks) / BOOKS_PER_PAGE))
        page = min(page, total_pages)

        start = (page - 1) * BOOKS_PER_PAGE
        page_ebooks = all_ebooks[start:start + BOOKS_PER_PAGE]

        html = render_shop_index(
            page_ebooks, ebook_dir, self.server.cover_cache_dir,
            self.server.base_url, self.server.auth_token,
            page, total_pages,
        )
        data = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def handle_shop_detail(self, filename):
        if "/" in filename or filename.startswith("."):
            self.send_error(403)
            return

        filepath = os.path.join(self.server.ebook_dir, filename)
        if not os.path.isfile(filepath):
            self.send_error(404)
            return

        html = render_shop_detail(
            filename, self.server.ebook_dir, self.server.cover_cache_dir,
            self.server.base_url, self.server.auth_token,
        )
        data = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def load_or_generate_token(token_file):
    """Load auth token from file, or generate and save a new one."""
    if os.path.isfile(token_file):
        with open(token_file, "r") as f:
            token = f.read().strip()
        if token:
            return token

    token = secrets.token_urlsafe(32)
    os.makedirs(os.path.dirname(token_file), exist_ok=True)
    with open(token_file, "w") as f:
        f.write(token + "\n")
    os.chmod(token_file, 0o600)
    print(f"Generated new auth token and saved to: {token_file}")
    return token


def main():
    parser = argparse.ArgumentParser(description="Tolino Ebook Server")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--ebook-dir", required=True)
    parser.add_argument("--base-url", required=True, help="External base URL (e.g. https://host:port)")
    parser.add_argument("--sync-base-url", default=None,
                        help="HTTP base URL for sync download links (for clients that can't do HTTPS)")
    parser.add_argument("--cover-cache-dir", required=True)
    parser.add_argument("--auth-token-file", required=True,
                        help="Path to file containing auth token (auto-generated if missing)")
    parser.add_argument("--vocab-db", default=None,
                        help="Path to vocabulary SQLite database (default: <state-dir>/vocab.db)")
    args = parser.parse_args()

    if not os.path.isdir(args.ebook_dir):
        print(f"Warning: ebook directory does not exist: {args.ebook_dir}")

    os.makedirs(args.cover_cache_dir, exist_ok=True)

    auth_token = load_or_generate_token(args.auth_token_file)

    # Initialize vocabulary database
    vocab_db = args.vocab_db or os.path.join(args.cover_cache_dir, "..", "vocab.db")
    vocab_db = os.path.abspath(vocab_db)
    init_vocab_db(vocab_db)

    server = HTTPServer(("127.0.0.1", args.port), EbookHandler)
    server.ebook_dir = args.ebook_dir
    server.base_url = args.base_url.rstrip("/")
    server.sync_base_url = (args.sync_base_url or args.base_url).rstrip("/")
    server.cover_cache_dir = args.cover_cache_dir
    server.auth_token = auth_token
    server.vocab_db_path = vocab_db

    print(f"Tolino Ebook Server listening on 127.0.0.1:{args.port}")
    print(f"Serving ebooks from: {args.ebook_dir}")
    print(f"Vocabulary DB: {vocab_db}")
    print(f"External base URL: {server.base_url}")
    print(f"Auth token: {auth_token}")
    server.serve_forever()


if __name__ == "__main__":
    main()
