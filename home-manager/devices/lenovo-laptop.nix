{ config, lib, pkgs, modulesPath, ... }:

let
  enable = config.custom.device == "lenovo-laptop";
in {
  config = lib.mkIf enable {
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
        sway = rec {
          laptopDisplay = "eDP-1";
          disp1 = laptopDisplay;
          disp2 = laptopDisplay;
        };
        waybar = {
          hwmonPath = null;
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
        diyStuff.enable = false;
        gaming.enable = false;
      };
    };
  };
}
