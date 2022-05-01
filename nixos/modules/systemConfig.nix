deviceName:
{ config, lib, ... }:

with lib;

{
  imports = [
    # Hardware specifics
    ./cpu_amd.nix
    ./cpu_intel.nix
    ./cpu_generic.nix
    ./gpu.nix
    ./gpu_amd.nix
    ./gpu_intel.nix
    ./gpu_nvidia.nix
    ./gpu_generic.nix

    ./swapfile.nix

    # Internationalisation specifics
    ./internationalization.nix

    # Shared settings
    ./grub.nix
    ./ssh.nix
    ./security.nix

    # Features
    ./audio.nix
    ./optimize_storage_space.nix
    ./powermanagement.nix
    (import ./networking.nix deviceName)
    ./bluetooth.nix
    ./virtualisation.nix
    ./adb.nix
    ./smartcards.nix

    ./wayland.nix
    ./home-manager_wayland.nix
    ./x11.nix
  ];

  options.custom = {
    enableVirtualisation = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable support for virtualisation.
        More specifically: docker, virtualbox, libvirtd
      '';
    };

    grub = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Use grub as boot loader.
        '';
      };
      useUEFI = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Specifies if grub should be installed for an UEFI system.
        '';
      };
    };

    cpuFreqGovernor = mkOption {
      type = types.nullOr (types.enum [ "ondemand" "powersave" "performance" ]);
      default = "ondemand";
      description = ''
        Specifies the cpu frequency governor to use.
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

    smartcards = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Specifies whether to enable smartcard support.
      '';
    };
  };


  config = {
    # System sanity checks
    assertions = [
      {
        assertion = !config.custom.grub.enable || config.custom.grub.useUEFI != null;
        message = "It must be specified whether grub is to be installed on an UEFI system!";
      }
    ];
  };
}
