{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.custom.internationalization;

  timeZone = cfg.timeZone;
  defaultLocale = cfg.defaultLocale;
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

    # Select internationalisation properties.
    time.timeZone = timeZone;
    i18n.defaultLocale = defaultLocale;
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

