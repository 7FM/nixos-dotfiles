{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
in lib.mkMerge [
{
  custom = {
    # System settings
    gpu = "amd";
    cpu = "amd";
    # gui = "wayland";
    gui = "hm-wayland";
    useDummySecrets = false;
    bluetooth = true;
    audio.backend = "pipewire";
    # Homemanager settings
    hm = {
      modules = {
        alacritty.enable = true;
        bash.enable = true;
        calendar.enable = true;
        easyeffects.enable = true;
        email.enable = true;
        git = {
          enable = true;
          identity_scripts.enable = true;
        };
        gtk.enable = true;
        neovim.enable = true;
        optimize_storage.enable = true;
        qt.enable = true;
        ssh.enable = true;
        sway = {
          laptopDisplay = null;
          disp1 = "DVI-D-1";
          disp1_pos = "0,0";
          disp1_res = "1920x1080@144Hz";
          disp2 = "HDMI-A-1";
          disp2_pos = "1920,0";
          disp2_res = "1920x1080";
          extraConfig = ''
            output "Toshiba America Info Systems Inc Toshiba-H2C 0x00008800" disable
            output "HDMI-A-2" pos 0 1080
          '';
        };
        waybar = {
          hwmonPath = "/sys/class/hwmon/hwmon1/temp3_input";
          thermalZone = null;
          gpu = {
            tempCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card1/device/hwmon/hwmon0/temp1_input";
            mhzFreqCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card1/device/pp_dpm_sclk | ${pkgs.gnugrep}/bin/egrep -o '[0-9]{0,4}Mhz \\W' | ${pkgs.gnused}/bin/sed 's/Mhz \\*//'";
            usageCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card1/device/gpu_busy_percent";
          };
        };
        xdg.enable = true;
        zsh.enable = true;
      };
      collections = {
        communication.enable = true;
        development.enable = true;
        diyStuff.enable = true;
        gaming.enable = true;
        gui_utilities.enable = true;
        media.enable = true;
        office.enable = true;
        utilities.enable = true;
      };
    };

  };
}
{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = with config.boot.kernelPackages; [ 
    # rtl8812au # Currently marked as broken in linux 5.16
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

  custom.grub = {
    enable = true;
    useUEFI = true;
  };
  custom.enableVirtualisation = true;
  custom.adb = "udevrules";
  custom.smartcards = true;
  custom.nano_conf.enable = true;
  custom.networking = {
    nfsSupport = true;
    wifiSupport = true;
    withNetworkManager = true;
    openvpn.client = {
      enable = true;
      autoConnect = false;
    };
  };
  custom.sshServer = {
   enable = true;
  };
  custom.security = {
    gnupg.enable = true;
    usbguard = {
      enforceRules = true;
      fixedRules = myTools.getSecret ../../nixos "usbguard-rules.nix";
    };
  };
  custom.internationalization = {
    defaultLcTime = "de_DE.UTF-8";
    defaultLcPaper = "de_DE.UTF-8";
    defaultLcMeasurement = "de_DE.UTF-8";
  };

  networking.interfaces.eno1 = {
    useDHCP = true;
    wakeOnLan.enable = true;
  };
  #networking.interfaces.enp7s0f3u3u4u4.useDHCP = true;

  networking.interfaces.wlp3s0.useDHCP = true;
  networking.wireless.interfaces = [
    "wlp3s0"
  ];

  services.udev = {
    packages = with pkgs; [
      platformio
    ];
  };
}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
