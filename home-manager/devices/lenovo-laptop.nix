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
      sway = rec {
        laptopDisplay = "eDP-1";
        disp1 = laptopDisplay;
        disp2 = laptopDisplay;
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
      diyStuff.enable = false;
      gaming.enable = false;
      gui_utilities.enable = true;
      media.enable = true;
      office.enable = true;
      utilities.enable = true;
    };
  };
}
