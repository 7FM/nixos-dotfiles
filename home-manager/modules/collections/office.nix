{ config, pkgs, lib, ... }:

let
#  useWayland = config.custom.gui == "wayland";
  useWayland = true;
in {

  imports = [
    (import ../firefox.nix { inherit useWayland; })
  ];

  home.packages = with pkgs; [
    # Some basic gui programs
    thunderbird
    gimp
    keepassxc
    libreoffice
    # needed to open urls from discord, vscode, etc...
    xdg-utils
    # printer utils
    system-config-printer
    # scanner utils
    gnome.simple-scan
  ];
}
