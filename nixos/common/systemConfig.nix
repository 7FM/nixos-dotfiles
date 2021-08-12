{ config, lib, ... }:

with lib;

{
  options.custom = {

    cpu = mkOption {
      type = types.nullOr (types.enum [ "amd" "intel" "generic" ]);
      default = null;
      description = ''
        Specifies cpu brand in use, to apply microcode patches or cpu specific settings!
      '';
    };

    gpu = mkOption {
      type = types.nullOr (types.enum [ "amd" "intel" "nvidia" "generic" ]);
      default = null;
      description = ''
        Specifies gpu brand in use, to apply specific settings!
      '';
    };

    gui = mkOption {
      type = types.nullOr (types.enum [ "x11" "wayland" "headless" ]);
      default = null;
      description = ''
        Specifies the user frontend to use.
      '';
    };

    useUEFI = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Specifies if grub should be installed for an UEFI system.
      '';
    };

    runSSHServer = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Specifies whether a ssh server should be run!
        This is automagically enabled when running in headless mode.
      '';
    };

    cpuFreqGovernor = mkOption {
      type = types.nullOr (types.enum [ "ondemand" "powersave" "performance" ]);
      default = "ondemand";
      description = ''
        Specifies the cpu frequency governor to use.
      '';
    };

    hostname = mkOption {
      type = types.str;
      default = "nixos";
      description = ''
        Specifies the hostname of this system.
      '';
    };
  };


  config = {
    # System sanity checks
    assertions = [
      {
        assertion = config.custom.gui != null;
        message = "A user frontend must be specified!";
      }
      {
        assertion = config.custom.gpu != null;
        message = "A gpu must be specified!";
      }
      {
        assertion = config.custom.cpu != null;
        message = "A cpu must be specified!";
      }
      {
        assertion = config.custom.useUEFI != null;
        message = "It must be specified whether grub is to be installed on an UEFI system!";
      }
    ];
  };
}
