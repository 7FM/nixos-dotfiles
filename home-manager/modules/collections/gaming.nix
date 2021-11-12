{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.gaming.communication.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Gaming
      steam
      steam-run
      lutris
      #wine
      winetricks
      wineWowPackages.full
    ];
  };
}
