{ config, lib, pkgs, modulesPath, ... }:

let
  enable = config.custom.device == "lenovo_laptop";
in {
  config = lib.mkIf enable {
    custom.hm = {
      modules = {
        xdg.enable = true;
        sway.enable = true;
        alacritty.enable = true;
        ssh.enable = true;
        git.enable = true;
        zsh.enable = true;
        neovim.enable = true;
        gtk.enable = true;
        qt.enable = true;
        email.enable = true;
        optimize_storage.enable = true;
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