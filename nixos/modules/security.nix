{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  runHeadless = config.custom.gui == "headless";

  cfg = config.custom.security.usbguard;
  fixedRules = cfg.fixedRules;
  enforce = cfg.enforceRules || fixedRules != null;
in {

  options.custom.security = with lib; {
    gnupg = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the gnupg agent.
        '';
      };
    };
    usbguard = {
      enforceRules = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enforces the usbguard rules and might make interactions impossible, if not properly configured.
          Still, it is strongly recommended to enable this option.
        '';
      };
      fixedRules = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = ''
          Running 'usbguard generate-policy' as root will generate
          a config for your currently plugged in devices.
          If you do not set this option, the USBGuard daemon will
          load it's policy rule set from '/var/lib/usbguard/rules.conf'
        '';
      };
    };
  };

  config = {
    # Keyring
    services.gnome.gnome-keyring.enable = !runHeadless && (config.custom.gui != "x11");

    # Polkit
    security.polkit.enable = true;

    # GnuPG
    programs.gnupg.agent = {
      enable = config.custom.security.gnupg.enable;
    };

    # Security
    services.usbguard = {
      enable = true;
      # For headless:
      package = if runHeadless then pkgs.usbguard-nox else pkgs.usbguard;
      implicitPolicyTarget = if enforce then "block" else "allow";
      rules = fixedRules;
    };

    # Enable support to update device firmware!
    services.fwupd.enable = true;

    # Allow unfree software :(
    nixpkgs.config.allowUnfree = true;

    # Enfore nixstore to be readonly
    boot.readOnlyNixStore = true;

    # User settings as i.e. the password may not be changed! Also no new users or groups can be added!
    users.mutableUsers = false;
    # Disable root login
    users.users.root.hashedPassword = "!";
    # Emergency mode requires root -> not usable anyway
    systemd.enableEmergencyMode = false;

    warnings = if (config.services.usbguard.implictPolicyTarget != "block") then [
      ''
        The fallback policy of usbguard should be set to block! Else no additional security is gained!
        HOWEVER, ensure that usbguard is setup with a policy before setting the fallback to block,
        else there might be no way to interact with the system!
      ''
    ] else [ ];

  };

}

