{ config, lib, ... }:

with lib;

let
  mkEnableDefaultTrueOption = name: mkEnableOption name // { default = true; };
in {
  imports = [
    ./alacritty.nix
    ./bash.nix
    ./easyeffects.nix
    ./email.nix
    ./git.nix
    ./gtk.nix
    ./neovim.nix
    ./optimize_storage_space.nix
    ./qt.nix
    ./scripts.nix
    ./ssh.nix
    ./sway.nix
    ./swaync.nix
    ./waybar.nix
    ./xdg.nix
    ./zsh.nix

    ./collections/communication.nix
    ./collections/development.nix
    ./collections/diyStuff.nix
    ./collections/gaming.nix
    ./collections/gui_utilities.nix
    ./collections/media.nix
    ./collections/office.nix
    ./collections/utilities.nix
  ];

  options.custom.hm = {

    modules = {
      alacritty.enable = mkEnableOption "the alacritty module";
      bash.enable = mkEnableDefaultTrueOption "the bash module";
      email.enable = mkEnableOption "the email module";
      easyeffects.enable = mkEnableOption "the easyeffects module";
      git.enable = mkEnableOption "the git module";
      gtk.enable = mkEnableOption "the gtk module";
      neovim.enable = mkEnableDefaultTrueOption "the neovim module";
      optimize_storage.enable = mkEnableOption "storage optimizations";
      qt.enable = mkEnableOption "the qt module";
      ssh.enable = mkEnableOption "the ssh module";
      xdg.enable = mkEnableDefaultTrueOption "the xdg module";
      zsh.enable = mkEnableDefaultTrueOption "the zsh module";
    };

    collections = {
      communication.enable = mkEnableOption "the communication collection";
      development.enable = mkEnableOption "the development collection";
      diyStuff.enable = mkEnableOption "the DIY stuff collection";
      gaming.enable = mkEnableOption "the gaming collection";
      gui_utilities.enable = mkEnableOption "the gui utilities collection";
      media.enable = mkEnableOption "the media collection";
      office.enable = mkEnableOption "the office collection";
      utilities.enable = mkEnableDefaultTrueOption "the utilities collection";
    };

  };


  config = {
    # sanity checks
    assertions = [
    ];
  };
}
