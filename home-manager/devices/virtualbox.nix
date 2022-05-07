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
        laptopDisplay = "";
        disp1 = laptopDisplay;
        disp2 = laptopDisplay;
        virtualboxWorkaround = true;
      };
      waybar = {
        hwmonPath = null;
        thermalZone = null;
      };
    };
    collections = {
      utilities.enable = true;
      gui_utilities.enable = true;
      communication.enable = false;
      development.enable = false;
      office.enable = true;
      media.enable = false;
      diyStuff.enable = false;
      gaming.enable = false;
    };
  };
}
