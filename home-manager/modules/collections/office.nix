{ config, pkgs, lib, ... }:

let
#  useWayland = config.custom.gui == "wayland";
  useWayland = true;

  enable = config.custom.hm.collections.office.enable;
in {
  config = lib.mkIf enable (lib.mkMerge [{
    # imports = [
    #   (import ../firefox.nix { inherit useWayland; })
    # ];

    home.packages = with pkgs; [
      # Some basic gui programs
      gimp
      keepassxc
      libreoffice
      hunspellDicts.de_DE # Dictionaries for spell checking in libreoffice
      hunspellDicts.en_US-large # Dictionaries for spell checking in libreoffice
      hunspellDicts.en_GB-large # Dictionaries for spell checking in libreoffice
      # PDF viewer
      libsForQt5.okular
      # needed to open urls from discord, vscode, etc...
      xdg-utils
      # printer utils
      system-config-printer
      # scanner utils
      gnome.simple-scan
      # For MTP connection with an android phone
      jmtpfs
    ];
  } (import ../submodule/firefox.nix { inherit useWayland; } { inherit config pkgs lib; })]);
}
