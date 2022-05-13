{ config, pkgs, lib, ... }:

let 
  bookmarks = [
    {
      hotkey = "d";
      path = "${config.home.homeDirectory}/docs";
    }
    { 
      hotkey = "D";
      path = "${config.home.homeDirectory}/Downloads";
    }
    {
      hotkey = "s";
      path = "${config.home.homeDirectory}/docs/Studium";
    }
    {
      hotkey = "S";
      path = "${config.home.homeDirectory}/screenshots";
    }
  ];

  toGtkBookmarks = bList: map (b: "file://${b.path}") bList;
  toNNNBookmarks = bList: builtins.listToAttrs (map (b: { name = b.hotkey; value = b.path; }) bList);
in {
  home.packages = with pkgs; [
    sxiv
  ];

  gtk.gtk3.bookmarks = toGtkBookmarks bookmarks;

  # NNN: CLI file browser 
  programs.nnn = {
    enable = true;
    package = pkgs.nnn.override { withNerdIcons = true; };

    bookmarks = toNNNBookmarks bookmarks;

    # Extra packages that are used for i.e. plugins
    extraPackages = with pkgs; [
      sxiv # Image viewer
      moc # CLI audio player
      unixtools.xxd # hexeditor
    ];

    plugins = {
      mappings = {
          v = "imgview";
          q = "mocq";
          e = "suedit";
          c = "rsynccp";
          h = "hexview";
      };

  #      src = (pkgs.fetchFromGitHub {
  #        owner = "jarun";
  #        repo = "nnn";
  #        rev = "v4.3";
  #        sha256 = "sha256-Hpc8YaJeAzJoEi7aJ6DntH2VLkoR6ToP6tPYn3llR7k=";
  #      }) + "/plugins";
      src = (pkgs.nnn.src) + "/plugins";
    };
  };

  xdg.desktopEntries.nnn = {
    type ="Application";
    name = "nnn";
    comment = "Terminal file manager";
    exec = "nnn %f";
    terminal = true;
    noDisplay = true;
    icon = "nnn";
    mimeType = [
      "inode/directory"
      "application/octet-stream"
      "multipart/x-zip"
      "application/zip"
      "application/zip-compressed"
      "application/x-zip-compressed"
      "application/x-gtar"
      "application/x-tar"
      "application/gzip"
      "application/x-xz"
      "application/x-7z-compressed"
      "application/x-rar-compressed"
      "application/x-bzip"
      "application/x-bzip2"
    ];
    categories = [" System" "FileTools" "FileManager" "ConsoleOnly"];
    # Keywords=File;Manager;Management;Explorer;Launcher
  };

  xdg.desktopEntries.sxiv = {
    type ="Application";
    name = "sxiv";
    comment = "Terminal image viewer";
    exec = "sxiv %f";
    terminal = true;
    noDisplay = true;
    icon = "sxiv";
    mimeType = [
      "image/bmp"
      "image/g3fax"
      "image/gif"
      "image/x-fits"
      "image/x-pcx"
      "image/x-portable-anymap"
      "image/x-portable-bitmap"
      "image/x-portable-graymap"
      "image/x-portable-pixmap"
      "image/x-psd"
      "image/x-sgi"
      "image/x-tga"
      "image/x-xbitmap"
      "image/x-xwindowdump"
      "image/x-xcf"
      "image/x-compressed-xcf"
      "image/x-sun-raster"
      "image/tiff"
      "image/jpeg"
      "image/x-psp"
      "image/png"
      "image/x-icon"
      "image/x-xpixmap"
      "image/x-exr"
      "image/webp"
      "image/x-webp"
      "image/heif"
      "image/heic"
      "image/avif"
      "image/svg+xml"
      "image/x-wmf"
      "image/jp2"
      "image/x-xcursor"
      "image/openraster"
    ];
    categories = [" System" "FileTools" "FileManager" "ConsoleOnly"];
    # Keywords=File;Manager;Management;Explorer;Launcher
  };

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "nnn.desktop" ];
  };

  # Enable cd on exit
  xdg.configFile."nnn/quitcd.bash_zsh".source = ../../configs/nnn/quitcd.bash_zsh;

  # initExtra and initExtraFirst are already in use... TODO find better solution!
  programs.zsh.initExtraBeforeCompInit = ''
    if [ -f "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/nnn/quitcd.bash_zsh" ]; then
    source "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/nnn/quitcd.bash_zsh"
    fi
  '';
}
