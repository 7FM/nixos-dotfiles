{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  useWayland = config.custom.gui == "wayland";
  useX11 = config.custom.gui == "x11";
in lib.mkMerge [
{
  custom = {
    # System settings
    gpu = "generic";
    cpu = "generic";
    gui = "wayland";
    useDummySecrets = true;
    bluetooth = false;
    audio.backend = "pipewire";
    # Homemanager settings
    hm = {
      modules = {
        alacritty = {
          enable = true;
          virtualboxWorkaround = true;
        };
        bash.enable = true;
        calendar.enable = true;
        email.enable = true;
        easyeffects.enable = true;
        git = {
          enable = true;
          identity_scripts.enable = true;
        };
        gtk.enable = true;
        neovim.enable = true;
        optimize_storage.enable = true;
        qt.enable = true;
        ssh.enable = true;
        sway = rec {
          laptopDisplay = "";
          disp1 = laptopDisplay;
          disp1_pos = null;
          disp1_res = null;
          disp2 = laptopDisplay;
          disp2_pos = null;
          disp2_res = null;
          extraConfig = null;
        };
        waybar = {
          hwmonPath = null;
          thermalZone = null;
        };
        xdg.enable = true;
        zsh.enable = true;
      };
      collections = {
        communication.enable = false;
        development.enable = false;
        diyStuff.enable = false;
        gaming.enable = false;
        gui_utilities.enable = true;
        media.enable = false;
        office.enable = true;
        utilities.enable = true;
      };
    };
  };
}
{
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

  custom.nano_conf.enable = true;
  networking.interfaces.enp0s3.useDHCP = true;
}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
