{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
in lib.mkMerge [
{
  custom = {
    # System settings
    gpu = "generic";
    cpu = "generic";
    gui = "headless";
    useDummySecrets = false;
    bluetooth = false;
    audio.backend = "none";
    # Homemanager settings
    hm = {
      modules = {
        alacritty.enable = false;
        bash.enable = true;
        calendar.enable = false;
        easyeffects.enable = false;
        email.enable = false;
        git = {
          enable = true;
          identity_scripts.enable = false;
        };
        gtk.enable = false;
        neovim.enable = true;
        optimize_storage.enable = true;
        qt.enable = false;
        ssh.enable = false;
        xdg.enable = true;
        zsh.enable = true;
      };
      collections = {
        communication.enable = false;
        development.enable = false;
        diyStuff.enable = false;
        gaming.enable = false;
        gui_utilities.enable = false;
        media.enable = false;
        office.enable = false;
        utilities.enable = true;
      };
    };
  };
}
{
  # File systems configuration for using the installer's partition layout
  fileSystems = {
    # Prior to 19.09, the boot partition was hosted on the smaller first partition
    # Starting with 19.09, the /boot folder is on the main bigger partition.
    # The following is to be used only with older images.
    /*
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    */
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  hardware.raspberry-pi."4" = {
    audio.enable = false;
    dwc2 = {
      enable = false;
    };
    i2c0.enable = false;
    i2c1.enable = false;
    poe-hat.enable = false;
    pwm0.enable = false;
    tc358743.enable = false;
    fkms-3d = {
      enable = false;
    };
  };

  custom.grub = {
    enable = false;
    #useUEFI = false;
  };
  custom.cpuFreqGovernor = "ondemand";
  custom.laptopPowerSaving = false;
  custom.enableVirtualisation = false;
  custom.smartcards = false;
  custom.nano_conf.enable = true;
  custom.networking = {
    nfsSupport = false;
    wifiSupport = false;
    withNetworkManager = false;
    openvpn.client = {
      enable = false;
      autoConnect = false;
    };
  };
  custom.security = {
    gnupg.enable = false;
    usbguard = {
      enforceRules = false;
      #fixedRules = myTools.getSecret ../../nixos "usbguard-rules.nix";
    };
  };
  custom.internationalization = {
    defaultLcTime = "de_DE.UTF-8";
    defaultLcPaper = "de_DE.UTF-8";
    defaultLcMeasurement = "de_DE.UTF-8";
  };

  custom.sshServer = {
    enable = true;
  };

  networking.interfaces.eth0.useDHCP = true;

  # Create an AP
  services.hostapd = {
    enable = true;
    ssid = myTools.getSecret ../../nixos "apName.nix";
    wpaPassphrase = myTools.getSecret ../../nixos "apPassword.nix";
    interface = "wlan0";
  };
  # Associate a dhcp server with this AP
  services.dhcpd4 = {
    enable = true;
    interfaces = [ "wlan0" ];
    extraConfig = ''
      subnet 192.168.42.0 netmask 255.255.255.0 {
        range 192.168.42.42 192.168.42.242;
        option subnet-mask 255.255.255.0;
        option broadcast-address 192.168.42.255;
        option routers 192.168.42.1;
      }
    '';
  };

  # Disable the dhcp client for our AP interface!
  #networking.interfaces.wlan0.useDHCP = true;
  #networking.wireless.interfaces = [
  #  "wlan0"
  #];
  networking.interfaces.wlan0 = {
    useDHCP = false;
    ipv4.addresses = [{
      address = "192.168.42.1";
      prefixLength = 24;
    }];
  };
}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
