{ useWayland ? true }:
{ config, pkgs, lib, ... }:

{
  home.sessionVariables = lib.mkIf useWayland {
    MOZ_ENABLE_WAYLAND = 1;
  };

  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      forceWayland = useWayland;
      extraPolicies = {
        ExtensionSettings = {};
      };
    };

    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      https-everywhere
      darkreader
      keepassxc-browser
      ghostery
      localcdn
      umatrix
      ublock-origin
    ];

    profiles = {
      tm = {
        bookmarks = import ../../configs/secrets/bookmarks.nix;

        settings = {
          "browser.search.region" = "GB";
          "browser.search.isUS" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.didSkipDefaultBrowserCheckOnFirstRun" = true;
          "browser.bookmarks.restore_default_bookmarks" = false;
          "browser.contentblocking.category" = "strict";
          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.startup.homepage" = "about:blank";
          "browser.newtabpage.enabled" = false;
          "browser.toolbars.bookmarks.visibility" = "always";

          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "doh-rollout.doneFirstRun" =  true;
          "doh-rollout.home-region" = "GB";
          "distribution.searchplugins.defaultLocale" = "en-GB";
          "general.useragent.locale" = "en-GB";

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
        };
      };
    };
  };

}
