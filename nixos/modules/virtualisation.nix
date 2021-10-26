{ config, pkgs, lib, ... }:

let
  isAmdCpu = config.custom.cpu == "amd";
  isIntelCpu = config.custom.cpu == "intel";
  isHeadless = config.custom.gui == "headless";
  isIntelGpu = config.custom.gpu == "intel";

  enable = config.custom.enableVirtualisation;
in {
  config = lib.mkIf enable {
    boot.kernelModules = [] ++
      (lib.optionals isAmdCpu [ "kvm-amd" ] ) ++ 
      (lib.optionals isIntelCpu [ "kvm-intel" ] )
    ;

    virtualisation = {
      docker = {
        enable = true;
      };

      virtualbox = {
        host = {
          enable = true;
          enableHardening = true;
          enableExtensionPack = true;
          headless = isHeadless;
        };
      };

      libvirtd = {
        enable = true;
        qemu.runAsRoot = false;
      };

      kvmgt = {
        # Allow Qemu/KVM guests to share integrated intel graphics
        enable = isIntelGpu;
      };
    };

    # virtualisation specific groups
    users.users.tm.extraGroups = [
      "kvm"
      "lxd"
      "docker"
      "libvirtd"
      "vboxusers"
    ];
  };
}

