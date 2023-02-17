{ config, pkgs, lib, ... }:

with lib;

let
  myTools = pkgs.myTools { osConfig = config; };
  cfg = config.custom.internationalization;

  timeZone = cfg.timeZone;
  defaultLocale = cfg.defaultLocale;
  defaultLcTime = cfg.defaultLcTime;
  defaultLcPaper = cfg.defaultLcPaper;
  defaultLcMeasurement = cfg.defaultLcMeasurement;
  keyboardLayout = cfg.keyboardLayout;
  consoleFont = cfg.consoleFont;

in {
  # Declare available module options
  options.custom.internationalization = {
    timeZone = mkOption {
      type = types.str;
      default = "Europe/Berlin";
      description = ''
        Global setting for the timezone to use.
      '';
    };

    defaultLocale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = ''
        Setting for the system language to use.
      '';
    };

    defaultLcTime = mkOption {
      type = types.str;
      default = defaultLocale;
      description = ''
        Setting for the system time representation to use.
      '';
    };

    defaultLcPaper = mkOption {
      type = types.str;
      default = defaultLocale;
      description = ''
        Setting for the system paper type (A4 vs. US letter) to use.
      '';
    };

    defaultLcMeasurement = mkOption {
      type = types.str;
      default = defaultLocale;
      description = ''
        Setting for the system measurement system (metric vs. US units) to use.
      '';
    };

    keyboardLayout = mkOption {
      type = types.str;
      default = "de";
      description = ''
        Global setting for the keyboard layout to use.
      '';
    };

    consoleFont = mkOption {
      type = types.str;
      default = "Lat2-Terminus16";
      description = ''
        Default console font to use.
      '';
    };
  };

  # Apply specified settings!
  config = {

    # Select internationalization properties.
    time.timeZone = timeZone;
    i18n = {
      defaultLocale = defaultLocale;
      extraLocaleSettings = {
        LC_TIME = defaultLcTime;
        LC_PAPER = defaultLcPaper;
        LC_MEASUREMENT = defaultLcMeasurement;
      };
    };
    console = {
      font = consoleFont;
      keyMap = keyboardLayout;
    };

    environment.sessionVariables = {
      XKB_DEFAULT_LAYOUT = keyboardLayout;
      XKB_DEFAULT_VARIANT = "";
    };

    # Configure keymap in X11
    services.xserver.layout = keyboardLayout;
    services.xserver.xkbVariant = "";
    # services.xserver.xkbOptions = "eurosign:e";

  };
}

