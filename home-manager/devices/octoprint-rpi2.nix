{ config, lib, pkgs, modulesPath, ... }:

{
  custom.hm = {
    modules = {
      xdg.enable = true;
      alacritty.enable = false;
      ssh.enable = false;
      git.enable = true;
      zsh.enable = true;
      bash.enable = true;
      neovim.enable = true;
      gtk.enable = false;
      qt.enable = false;
      email.enable = false;
      optimize_storage.enable = true;
    };
    collections = {
      utilities.enable = true;
      gui_utilities.enable = false;
      communication.enable = false;
      development.enable = false;
      office.enable = false;
      media.enable = false;
      diyStuff.enable = false;
      gaming.enable = false;
    };
  };
}
