{ config, lib, pkgs, modulesPath, ... }:

{
  custom.hm = {
    modules = {
      alacritty.enable = false;
      bash.enable = true;
      easyeffects.enable = false;
      email.enable = false;
      git.enable = true;
      gtk.enable = false;
      neovim.enable = true;
      optimize_storage.enable = true;
      qt.enable = false;
      ssh.enable = false;
      xdg.enable = true;
      zsh.enable = true;
    };
    collections = {
      communication.enable = false;
      development.enable = false;
      diyStuff.enable = false;
      gaming.enable = false;
      gui_utilities.enable = false;
      media.enable = false;
      office.enable = false;
      utilities.enable = true;
    };
  };
}
