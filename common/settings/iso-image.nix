{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
in lib.mkMerge [
{
  custom = {
    # System settings
    gpu = "generic";
    cpu = "generic";
    # gui = "wayland";
    gui = "hm-wayland";
    useDummySecrets = true;
    bluetooth = true;
    audio.backend = "pipewire";
    # Homemanager settings
    hm = {
      modules = {
        alacritty.enable = true;
        bash.enable = true;
        calendar.enable = false;
        easyeffects.enable = true;
        email.enable = false;
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
          disp1 = "HDMI-A-1"; # TODO can we allow DP as well? hardcoding for an ISO image seems wrong
          disp2 = "HDMI-A-1";
        };
        waybar = {
          # hwmonPath = null;
          # thermalZone = 2;
          # gpu = {
          #   tempCmd = null;
          #   mhzFreqCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card1/gt_cur_freq_mhz";
          #   usageCmd = null;
          # };
        };
        xdg.enable = true;
        zsh.enable = true;
      };
      collections = {
        communication.enable = true;
        development.enable = true;
        diyStuff.enable = false;
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
  custom.grub = {
    enable = false;
  };
  custom.cpuFreqGovernor = "ondemand";
  custom.laptopPowerSaving = true;
  custom.enableVirtualisation = true;
  custom.adb = "disabled";
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
    };
  };
  custom.internationalization = {
    defaultLcTime = "de_DE.UTF-8";
    defaultLcPaper = "de_DE.UTF-8";
    defaultLcMeasurement = "de_DE.UTF-8";
  };

  services.udev = {
    packages = with pkgs; [
      platformio
      libsigrok
    ];
  };

  fonts.fontconfig.enable = lib.mkForce true;

  # TODO can we remove the nixos user?

  # TODO use secrets here, make it somehow changeable
  # TODO do not hardcode the user name!!!
  users.users."tm".hashedPassword = lib.mkForce "TODO_THIS_IS_AN_INVALID_HASH_CHANGE_ME";
}
]
