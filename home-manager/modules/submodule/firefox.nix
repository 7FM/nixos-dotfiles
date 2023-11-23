{ config, pkgs, lib, osConfig, ... }:

let
  userName = config.home.username;
  myTools = pkgs.myTools { inherit osConfig; };
in {
  home.packages = with pkgs.nur.repos.wolfangaukang; [ vdhcoapp ];

  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      nativeMessagingHosts = with pkgs.nur.repos.wolfangaukang; [ vdhcoapp ];
      extraPolicies = {
        ExtensionSettings = {};
      };
    };

    profiles = {
      "${userName}" = {
        extensions = with pkgs.nur.repos.rycee.firefox-addons; let 
          video-downloaderhelper = buildFirefoxXpiAddon rec {
            pname = "video-downloadhelper";
            version = "7.6.6";
            addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4040817/video_downloadhelper-${version}.xpi";
            sha256 = "sha256-RgtkNIpmFsh73q2F9iJqbyLez8WzNFjZV3d3t2JDjIo=";
            meta = with lib;
            {
              description = "The easy way to download and convert Web videos from hundreds of YouTube-like sites.";
              license = licenses.unfree;
              platforms = platforms.all;
            };
          };
        in [
          darkreader
          keepassxc-browser
          ghostery
          localcdn
          umatrix
          ublock-origin
          video-downloaderhelper

          grammarly
          languagetool
        ];

        bookmarks = myTools.getSecret ../../configs "bookmarks.nix";

        settings = {
          "browser.search.region" = "GB";
          "browser.search.isUS" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.didSkipDefaultBrowserCheckOnFirstRun" = true;
          "browser.bookmarks.restore_default_bookmarks" = false;
          "browser.contentblocking.category" = "strict";
          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.urlbar.suggest.openpage" = false;
          "browser.startup.homepage" = "about:blank";
          "browser.newtabpage.enabled" = false;
          "browser.toolbars.bookmarks.visibility" = "always";

          "pdfjs.defaultZoomValue" = "page-fit";

          "extensions.update.autoUpdateDefault" = false;
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "doh-rollout.doneFirstRun" =  true;
          "doh-rollout.home-region" = "GB";
          "distribution.searchplugins.defaultLocale" = "en-GB";
          "general.useragent.locale" = "en-GB";

          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "browser.discovery.enabled" = false;
          "app.shield.optoutstudies.enabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;

          "media.eme.enabled" = true;

          "signon.autofillForms" = false;
          "signon.generation.enabled" = false;
          "signon.rememberSignons" = false;

          # Notifications:
          # Block notifications by default
          #"permissions.default.desktop-notification" = "2";
          # this is a master switch, you won't get any desktop notifications from sites
          #"dom.webnotifications.enabled" = false;
          # sites can still generate desktop notifications while you have a tab open to the site:
          "dom.webnotifications.serviceworker.enabled" = false;
          # disable BACKGROUND UPDATES
          "dom.push.enabled" = false;
        };
      };
    };
  };

  # use firefox by default for the following mime types
  xdg.mimeApps = {
    associations.added = {
      "image/svg+xml" = "firefox.desktop";
    };
    defaultApplications = {
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/chrome" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "application/x-extension-htm" = [ "firefox.desktop" ];
      "application/x-extension-html" = [ "firefox.desktop" ];
      "application/x-extension-shtml" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "application/x-extension-xhtml" = [ "firefox.desktop" ];
      "application/x-extension-xht" = [ "firefox.desktop" ];
      "application/pdf" = [ "firefox.desktop" ];
    };
  };

}
