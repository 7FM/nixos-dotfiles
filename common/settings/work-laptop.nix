{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
in lib.mkMerge [
{
  custom = {
    # System settings
    gpu = "intel";
    cpu = "intel";
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
        sway = rec {
          laptopDisplay = "eDP-1";
          touchpad = "1267:12793:ELAN067C:00_04F3:31F9_Touchpad";
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
          thermalZone = 2;
          gpu = {
            tempCmd = null;
            mhzFreqCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card1/gt_cur_freq_mhz";
            usageCmd = null;
          };
        };
        xdg.enable = true;
        zsh.enable = true;
      };
      collections = {
        communication.enable = true;
        development.enable = true;
        diyStuff.enable = true;
        gaming.enable = false;
        gui_utilities.enable = true;
        media.enable = true;
        office.enable = true;
        utilities.enable = true;
      };
    };

  };
}
{
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  # boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/6fb73a7c-c0e4-44da-a042-2b3d4fea6e9b";
      fsType = "ext4";
    };
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9165-2C9F";
      fsType = "vfat";
    };

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-f775e6dc-1800-4ef4-8a47-5f24e0a7fc2d".device = "/dev/disk/by-uuid/f775e6dc-1800-4ef4-8a47-5f24e0a7fc2d";
  boot.initrd.luks.devices."luks-f775e6dc-1800-4ef4-8a47-5f24e0a7fc2d".keyFile = "/crypto_keyfile.bin";


  boot.initrd.luks.devices."luks-a06e8b12-a88a-4700-b23e-0a38ef1f2884".device = "/dev/disk/by-uuid/a06e8b12-a88a-4700-b23e-0a38ef1f2884";

  swapDevices =
    [ { device = "/dev/disk/by-uuid/eea4d07b-47d7-460c-8ca7-528a9a1b1db2"; }
    ];

  # high-resolution display
  #TODO adjust fonts

  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = config.hardware.trackpoint.enable;

  # Autostart WWAN service
  systemd.services.ModemManager.wantedBy = [ "network.target" ];
  hardware.usb-modeswitch.enable = true;

  # Some applications
  environment.systemPackages = with pkgs; [ 
    # Also install a gui frontend for modemmanager
    modem-manager-gui
  ];

  # systemd.paths.setup_wwan = {
  #   wantedBy = [ "ModemManager.service" "network.target" ];
  #   pathConfig.PathExists = "/dev/cdc-wdm0";
  # };
  # systemd.services.setup_wwan = {
  #   script = ''
  #     ${pkgs.libqmi}/bin/qmicli -p -d /dev/cdc-wdm0 --device-open-mbim --dms-set-fcc-authentication
  #   '';
  #   before = [ "ModemManager.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  # };

  # networking.networkmanager.fccUnlockScripts = let id = "1199:9079"; in [{
  #     inherit id;
  #     path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/${id}";
  # }];

  custom.grub = {
    enable = true;
    useUEFI = true;
  };
  custom.cpuFreqGovernor = "powersave";
  custom.laptopPowerSaving = true;
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
  custom.security = {
    gnupg.enable = true;
    usbguard = {
      enforceRules = false;
      # fixedRules = myTools.getSecret ../../nixos "usbguard-rules.nix";
    };
  };
  custom.internationalization = {
    defaultLcTime = "de_DE.UTF-8";
    defaultLcPaper = "de_DE.UTF-8";
    defaultLcMeasurement = "de_DE.UTF-8";
  };

  networking.interfaces.wlp0s20f3.useDHCP = true;
  networking.wireless.interfaces = [
    "wlp0s20f3"
  ];
  networking.interfaces.wwan0.useDHCP = true;
  #networking.interfaces.enp7s0f3u3u4u4.useDHCP = true;

  services.udev = {
    packages = with pkgs; [
      platformio
      libsigrok
    ];

    extraRules = ''
      # Tolino Page 2 in Fastboot mode
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="0d02", MODE="0666", GROUP="plugdev"
      # Tolino Page 2 in ADB mode
      SUBSYSTEM=="usb", ATTR{idVendor}=="1f85", ATTR{idProduct}=="6052", MODE="0666", GROUP="plugdev"
      # Tolino Page 2 in TWRP recovery mode
      SUBSYSTEM=="usb", ATTR{idVendor}=="1f85", ATTR{idProduct}=="6056", MODE="0666", GROUP="plugdev"
    '';
  };

}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
