# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
in (lib.mkMerge [{
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "acpi_call" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/0061e991-0ff8-4887-abfe-b94652ffbc8b";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };

  boot.initrd.luks.devices."luks".device = "/dev/disk/by-uuid/c6633503-8f49-42b5-86a7-35554d7e7a4b";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F486-1131";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/0061e991-0ff8-4887-abfe-b94652ffbc8b";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" "noatime" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/0061e991-0ff8-4887-abfe-b94652ffbc8b";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };

  fileSystems."/var/log" =
    { device = "/dev/disk/by-uuid/0061e991-0ff8-4887-abfe-b94652ffbc8b";
      fsType = "btrfs";
      options = [ "subvol=log" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/69b51e21-6b8c-4267-abbe-4ac3ac584d62"; }
    ];

  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;

  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = config.hardware.trackpoint.enable;

  # automatic screen orientation
  hardware.sensor.iio.enable = true;

  # SSD optimization
  services.fstrim.enable = true;

  # Autostart WWAN service
  #systemd.services.ModemManager.wantedBy = [ "network.target" ];

  # Fingerprint reader: add fingerprint with fprintd-enroll
  # services.fprintd.enable = true;

  # Gnome 40 introduced a new way of managing power, without tlp.
  # However, these 2 services clash when enabled simultaneously.
  # https://github.com/NixOS/nixos-hardware/issues/260
  services.tlp.enable = lib.mkDefault ((lib.versionOlder (lib.versions.majorMinor lib.version) "21.05")
                                      || !config.services.power-profiles-daemon.enable);

  custom.useUEFI = true;
  custom.cpuFreqGovernor = "powersave";
  custom.enableVirtualisation = true;
  custom.adb = "udevrules";
  custom.networking = {
    wifiSupport = true;
    withNetworkManager = true;
  };
  custom.security.usbguard = {
    enforceRules = true;
    fixedRules = myTools.getSecret ../. "usbguard-rules.nix";
  };

  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;
  networking.wireless.interfaces = [
    "wlp4s0"
  ];
  networking.interfaces.wwp0s20f0u6i12.useDHCP = true;
} (import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })])
