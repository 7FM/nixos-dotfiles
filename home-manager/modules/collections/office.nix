{ config, pkgs, lib, ... }:

let
#  useWayland = config.custom.gui == "wayland";
  useWayland = true;

  enable = config.custom.hm.collections.office.enable;
in {
  config = lib.mkIf enable {
    imports = [
      (import ../firefox.nix { inherit useWayland; })
    ];

    home.packages = with pkgs; [
      # Some basic gui programs
      thunderbird
      gimp
      keepassxc
      libreoffice
      hunspellDicts.de_DE # Dictionaries for spell checking in libreoffice
      hunspellDicts.en_US-large # Dictionaries for spell checking in libreoffice
      hunspellDicts.en_GB-large # Dictionaries for spell checking in libreoffice
      libsForQt5.okular # PDF viewer
      # needed to open urls from discord, vscode, etc...
      xdg-utils
      # printer utils
      system-config-printer
      # scanner utils
      gnome.simple-scan
    ];
  };
}
