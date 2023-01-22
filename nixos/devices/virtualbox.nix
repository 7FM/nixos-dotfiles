{ config, lib, pkgs, modulesPath, ... }:

let
  useWayland = config.custom.gui == "wayland";
  useX11 = config.custom.gui == "x11";
in {
  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/792a19db-64fd-4d54-ae33-ef2387429bb5";
      fsType = "ext4";
    };

  swapDevices = [ ];

  environment.sessionVariables = if useWayland then {
    # Wayland fix invisible cursor
    WLR_NO_HARDWARE_CURSORS = "1";
  } else null;

  # VirtualBox specifics
  virtualisation.virtualbox.guest = {
    enable = true;
    x11 = useX11;
  };

  # Remove fsck at startup which fails with VirtualBox
  boot.initrd.checkJournalingFS = false;

  custom.grub = {
    enable = true;
    useUEFI = false;
  };
  custom.swapfile = {
    enable = true;
    size = 1024;
  };

  networking.interfaces.enp0s3.useDHCP = true;
}
