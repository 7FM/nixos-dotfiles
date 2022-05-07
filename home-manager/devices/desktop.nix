{ config, lib, pkgs, modulesPath, ... }:

{
  custom.hm = {
    modules = {
      xdg.enable = true;
      alacritty.enable = true;
      ssh.enable = true;
      git.enable = true;
      zsh.enable = true;
      bash.enable = true;
      neovim.enable = true;
      gtk.enable = true;
      qt.enable = true;
      email.enable = true;
      optimize_storage.enable = true;
      sway = {
        laptopDisplay = null;
        disp1 = "DVI-D-1";
        disp2 = "HDMI-A-1";
      };
      waybar = {
        hwmonPath = "/sys/class/hwmon/hwmon1/temp1_input";
        thermalZone = null;
        gpu = {
          tempCmd = "cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input";
          mhzFreqCmd = "cat /sys/class/drm/card0/device/pp_dpm_sclk | egrep -o '[0-9]{0,4}Mhz \\W' | sed 's/Mhz \\*//'";
          usageCmd = "cat /sys/class/drm/card0/device/gpu_busy_percent";
        };
      };
    };
    collections = {
      utilities.enable = true;
      gui_utilities.enable = true;
      communication.enable = true;
      development.enable = true;
      office.enable = true;
      media.enable = true;
      diyStuff.enable = true;
      gaming.enable = true;
    };
  };
}
