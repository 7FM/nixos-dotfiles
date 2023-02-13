{ config, lib, pkgs, modulesPath, ... }:

{
  custom.hm = {
    modules = {
      alacritty.enable = true;
      bash.enable = true;
      easyeffects.enable = true;
      email.enable = true;
      git.enable = true;
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
          tempCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input";
          mhzFreqCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card0/device/pp_dpm_sclk | ${pkgs.gnugrep}/bin/egrep -o '[0-9]{0,4}Mhz \\W' | ${pkgs.gnused}/bin/sed 's/Mhz \\*//'";
          usageCmd = "${pkgs.coreutils}/bin/cat /sys/class/drm/card0/device/gpu_busy_percent";
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
}
