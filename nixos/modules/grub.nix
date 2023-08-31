{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  cfg = config.custom.grub;
  enable = cfg.enable;
  useUEFI = cfg.useUEFI;
in lib.mkIf enable {
  # Use the GRUB boot loader.
  boot.loader.grub = {
    enable = true;
    memtest86.enable = true;
  };

  boot.loader.grub.efiSupport = useUEFI;
  boot.loader.efi.canTouchEfiVariables = useUEFI;
  #boot.loader.grub.efiInstallAsRemovable = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.systemd-boot = {
    enable = false;
    memtest86.enable = true;
  };

  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = if useUEFI then "nodev" else "/dev/sda"; # or "nodev" for efi only

  # Check if other OS are installed and if so add them to the grub menu!
  boot.loader.grub.useOSProber = true;
}

