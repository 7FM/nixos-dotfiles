{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  enable = osConfig.custom.hm.collections.office.enable;
in
{
  config = lib.mkIf enable (
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          # Some basic gui programs
          gimp
          keepassxc
          libreoffice
          hunspellDicts.de_DE # Dictionaries for spell checking in libreoffice
          hunspellDicts.en_US-large # Dictionaries for spell checking in libreoffice
          hunspellDicts.en_GB-large # Dictionaries for spell checking in libreoffice
          # PDF viewer
          kdePackages.okular
          # needed to open urls from discord, vscode, etc...
          xdg-utils
          # printer utils
          system-config-printer
          # scanner utils
          simple-scan
          # For MTP connection with an android phone: `aft-mtp-mount <dir>`
          # (jmtpfs and simple-mtpfs were both removed from nixpkgs as
          # unmaintained; this one is the same FUSE-mount idea)
          android-file-transfer
        ];
      }
      (import ../submodule/firefox.nix {
        inherit
          config
          pkgs
          lib
          osConfig
          ;
      })
    ]
  );
}
