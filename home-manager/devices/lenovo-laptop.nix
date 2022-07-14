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
          mhzFreqCmd = "${pkgs.coreutils-full}/bin/cat /sys/class/drm/card0/gt_cur_freq_mhz";
          usageCmd = null;
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
      diyStuff.enable = false;
      gaming.enable = false;
    };
  };
}
