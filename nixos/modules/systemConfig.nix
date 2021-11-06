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
      type = types.nullOr (types.enum [ "x11" "wayland" "headless" "hm-wayland" ]);
      default = null;
      description = ''
        Specifies the user frontend to use.
      '';
    };

    enableVirtualisation = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable support for virtualisation.
        More specifically: docker, virtualbox, libvirtd
      '';
    };

    useUEFI = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Specifies if grub should be installed for an UEFI system.
      '';
    };

    useSwapFile = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Specifies whether a swap file should used instead of a swap partition.
      '';
    };

    swapFileSize = mkOption {
      type = types.ints.positive;
      default = 20 * 1024;
      description = ''
        Specifies the swap file size in MiB.
      '';
    };

    swapFilePath = mkOption {
      type = types.str;
      default = "/swapfile";
      description = ''
        Specifies the swap file path.
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

    bluetooth = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable Bluetooth Support!
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

    adb = mkOption {
      type = types.enum [ "disabled" "global" "udevrules" ];
      default = "disabled";
      description = ''
        Specifies whether and how to add support for adb.
        "global" installs adb globally whereas "udevrules" only install the required udev rules and adb must be installed via i.e. homemanager.
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
