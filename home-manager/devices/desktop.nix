{ config, lib, pkgs, modulesPath, ... }:

{
  custom.hm = {
    modules = {
      xdg.enable = true;
      alacritty.enable = true;
      ssh.enable = true;
      git.enable = true;
      zsh.enable = true;
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
