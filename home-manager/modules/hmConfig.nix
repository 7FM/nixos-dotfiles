{ config, lib, ... }:

with lib;

let
  mkEnableDefaultTrueOption = name: mkEnableOption name // { default = true; };
in {
  imports = [
    ./xdg.nix
    ./sway.nix
    ./alacritty.nix
    ./ssh.nix
    ./git.nix
    ./zsh.nix
    ./neovim.nix
    ./gtk.nix
    ./qt.nix
    ./email.nix
    ./optimize_storage_space.nix

    ./collections/utilities.nix
    ./collections/gui_utilities.nix
    ./collections/communication.nix
    ./collections/development.nix
    ./collections/office.nix
    ./collections/media.nix
    ./collections/diyStuff.nix
    ./collections/gaming.nix
  ];

  options.custom.hm = {

    modules = {
      xdg.enable = mkEnableDefaultTrueOption "the xdg module";
      sway.enable = mkEnableOption "the sway module";
      alacritty.enable = mkEnableOption "the alacritty module";
      ssh.enable = mkEnableOption "the ssh module";
      git.enable = mkEnableOption "the git module";
      zsh.enable = mkEnableDefaultTrueOption "the zsh module";
      neovim.enable = mkEnableDefaultTrueOption "the neovim module";
      gtk.enable = mkEnableOption "the gtk module";
      qt.enable = mkEnableOption "the qt module";
      email.enable = mkEnableOption "the email module";
      optimize_storage.enable = mkEnableOption "storage optimizations";
    };

    collections = {
      utilities.enable = mkEnableDefaultTrueOption "the utilities collection";
      gui_utilities.enable = mkEnableOption "the gui utilities collection";
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
