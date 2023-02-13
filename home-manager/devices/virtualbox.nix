{ config, lib, pkgs, modulesPath, ... }:

{
  custom.hm = {
    modules = {
      alacritty = {
        enable = true;
        virtualboxWorkaround = true;
      };
      bash.enable = true;
      email.enable = true;
      easyeffects.enable = true;
      git.enable = true;
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
}
