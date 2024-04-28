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
          touchpad = "2:7:SynPS/2_Synaptics_TouchPad";
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
          gpu = {
            tempCmd = null;
            mhzFreqCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card0/gt_cur_freq_mhz";
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
  #boot.binfmt.emulatedSystems = [ "armv7l-linux" ];

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
  #TODO adjust fonts

  hardware.trackpoint.enable = true;
  hardware.trackpoint.emulateWheel = config.hardware.trackpoint.enable;

  # automatic screen orientation
  hardware.sensor.iio.enable = true;

  # SSD optimization
  services.fstrim.enable = true;

  # Autostart WWAN service
  systemd.services.ModemManager.wantedBy = [ "network.target" ];
  hardware.usb-modeswitch.enable = true;

  # Some applications
  environment.systemPackages = with pkgs; [ 
    # Also install a gui frontend for modemmanager
    modem-manager-gui

    # A somewhat useful touch-pen drawing application
    xournalpp
    rnote
  ];

  systemd.paths.setup_wwan = {
    wantedBy = [ "ModemManager.service" "network.target" ];
    pathConfig.PathExists = "/dev/cdc-wdm0";
  };
  systemd.services.setup_wwan = {
    script = ''
      ${pkgs.libqmi}/bin/qmicli -p -d /dev/cdc-wdm0 --device-open-mbim --dms-set-fcc-authentication
    '';
    before = [ "ModemManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  networking.networkmanager.fccUnlockScripts = let id = "1199:9079"; in [{
      inherit id;
      path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/${id}";
  }];

  # Fingerprint reader: add fingerprint with fprintd-enroll
  # services.fprintd.enable = true;

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
      enforceRules = true;
      fixedRules = myTools.getSecret ../../nixos "usbguard-rules.nix";
    };
  };
  custom.internationalization = {
    defaultLcTime = "de_DE.UTF-8";
    defaultLcPaper = "de_DE.UTF-8";
    defaultLcMeasurement = "de_DE.UTF-8";
  };

  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;
  networking.wireless.interfaces = [
    "wlp4s0"
  ];
  networking.interfaces.wwp0s20f0u6i12.useDHCP = true;

  services.udev = {
    packages = with pkgs; [
      platformio
    ];
  };

}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
