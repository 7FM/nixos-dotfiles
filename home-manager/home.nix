{ config, pkgs, ... }:

{
  imports = [
    modules/xdg.nix
    modules/sway.nix
    modules/alacritty.nix
    modules/ssh.nix
    modules/git.nix
    modules/zsh.nix
    modules/neovim.nix
    modules/gtk.nix
    modules/qt.nix
    modules/email.nix

    modules/collections/utilities.nix
    modules/collections/communication.nix
    modules/collections/development.nix
    modules/collections/office.nix
    modules/collections/media.nix
    #modules/collections/diyStuff.nix
    #modules/collections/gaming.nix

    modules/optimize_storage_space.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "tm";
  home.homeDirectory = "/home/tm";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}
