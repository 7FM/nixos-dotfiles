{ config, lib, ... }:

with lib;

let
  mkEnableDefaultTrueOption = name: mkEnableOption name // { default = true; };
in {
  options.custom.hm = {

    modules = {
      xdg.enable = mkEnableOption "the xdg module";
      sway.enable = mkEnableOption "the sway module";
      alacritty.enable = mkEnableOption "the alacritty module";
      ssh.enable = mkEnableOption "the ssh module";
      git.enable = mkEnableOption "the git module";
      zsh.enable = mkEnableOption "the zsh module";
      neovim.enable = mkEnableOption "the neovim module";
      gtk.enable = mkEnableOption "the gtk module";
      qt.enable = mkEnableOption "the qt module";
      email.enable = mkEnableOption "the email module";
      optimize_storage.enable = mkEnableOption "storage optimizations";
    };

    collections = {
      utilities.enable = mkEnableOption "the utilities collection";
      communication.enable = mkEnableOption "the communication collection";
      development.enable = mkEnableOption "the development collection";
      office.enable = mkEnableOption "the office collection";
      media.enable = mkEnableOption "the media collection";
      diyStuff.enable = mkEnableOption "the DIY stuff collection";
      gaming.enable = mkEnableOption "the gaming collection";
    };

  };


  config = {
    # sanity checks
    assertions = [
    ];
  };
}
