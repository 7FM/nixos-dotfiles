# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

let
  enable = config.custom.device == "desktop";
in {
  config = lib.mkIf enable {
    imports =
      [ (modulesPath + "/installer/scan/not-detected.nix")
      ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "wl" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ 
      broadcom_sta
      rtl8812au
    ];

    boot.initrd.luks.devices."luks".device = "/dev/disk/by-uuid/b2a512fd-5112-41e0-8228-58149ca65618";

    fileSystems = {
      "/boot" = {
        device = "/dev/disk/by-uuid/494A-BA1F";
        fsType = "vfat";
      };

      "/" = {
        device = "/dev/disk/by-uuid/99f14769-79f4-4ccf-bcb8-cc7061d9dde8";
        fsType = "btrfs";
        options = [ "subvol=root" "compress=zstd" "noatime" ];
      };

      "/home" = {
        device = "/dev/disk/by-uuid/99f14769-79f4-4ccf-bcb8-cc7061d9dde8";
        fsType = "btrfs";
        options = [ "subvol=home" "compress=zstd" "noatime" ];
      };

      "/nix" = {
        device = "/dev/disk/by-uuid/99f14769-79f4-4ccf-bcb8-cc7061d9dde8";
        fsType = "btrfs";
        options = [ "subvol=nix" "compress=zstd" "noatime" ];
      };

      "/var/log" = {
        device = "/dev/disk/by-uuid/99f14769-79f4-4ccf-bcb8-cc7061d9dde8";
        fsType = "btrfs";
        options = [ "subvol=log" "compress=zstd" "noatime" ];
        neededForBoot = true;
      };

      "/home/tm/games" = {
        device = "/dev/disk/by-partuuid/63d76ef1-f532-5946-a17e-ad4079f61f09";
        fsType = "btrfs";
        options = [ "compress=zstd" "noatime" ];
      };

      "/home/tm/docs" = {
        device = "/dev/disk/by-partuuid/7a8d7f67-77eb-4723-b452-de0c9eb527cf";
        fsType = "btrfs";
        options = [ "compress=zstd" "noatime" ];
      };
    };


    swapDevices = [{
      device = "/dev/disk/by-uuid/002b659d-f634-4cc4-8c97-9b3be20b9bfb";
    }];

    # System settings
    custom.gpu = "amd";
    custom.cpu = "amd";
    custom.gui = "wayland";
    #custom.gui = "hm-wayland";
    custom.useUEFI = true;
    custom.bluetooth = true;
    custom.enableVirtualisation = true;
    custom.adb = "udevrules";

    networking.interfaces.eno1.useDHCP = true;
    #networking.interfaces.enp11s0f3u3u4u4.useDHCP = true;
  };
}
