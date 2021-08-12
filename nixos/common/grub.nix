{ config, pkgs, lib, ... }:

let
  useUEFI = config.custom.useUEFI;
in {
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  boot.loader.grub.efiSupport = useUEFI;
  #boot.loader.grub.efiInstallAsRemovable = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.systemd-boot.enable = useUEFI;

  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = if useUEFI then "nodev" else "/dev/sda"; # or "nodev" for efi only

  # Check if other OS are installed and if so add them to the grub menu!
  boot.loader.grub.useOSProber = true;
}

