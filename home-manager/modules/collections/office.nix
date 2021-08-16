{ config, pkgs, lib, ... }:

let
#  useWayland = config.custom.gui == "wayland";
  useWayland = true;
in {
  home.packages = with pkgs; [
    # Some basic gui programs
    (if useWayland then firefox-wayland else firefox)
    thunderbird
    gimp
    vlc
    keepassxc
  ];
}
