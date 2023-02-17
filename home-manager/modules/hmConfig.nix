{ ... }:

{
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
}
