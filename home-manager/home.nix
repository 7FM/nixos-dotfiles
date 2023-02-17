{ deviceName, userName, config, pkgs, ... }:

{
  imports = [
    ./modules/alacritty.nix
    ./modules/bash.nix
    ./modules/easyeffects.nix
    ./modules/email.nix
    ./modules/git.nix
    ./modules/gtk.nix
    ./modules/neovim.nix
    ./modules/optimize_storage_space.nix
    ./modules/qt.nix
    ./modules/scripts.nix
    ./modules/ssh.nix
    ./modules/sway.nix
    ./modules/swaync.nix
    ./modules/waybar.nix
    ./modules/xdg.nix
    ./modules/zsh.nix

    ./modules/collections/communication.nix
    ./modules/collections/development.nix
    ./modules/collections/diyStuff.nix
    ./modules/collections/gaming.nix
    ./modules/collections/gui_utilities.nix
    ./modules/collections/media.nix
    ./modules/collections/office.nix
    ./modules/collections/utilities.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = userName;
  home.homeDirectory = "/home/${userName}";

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
