{ config, pkgs, lib, ... }:

let
#  useWayland = config.custom.gui == "wayland";
  useWayland = true;
in {
  home.sessionVariables = lib.mkIf useWayland {
    MOZ_ENABLE_WAYLAND = 1;
  };

  home.packages = with pkgs; [
    # Some basic gui programs
    (if useWayland then firefox-wayland else firefox)
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
