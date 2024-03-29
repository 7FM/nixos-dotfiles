{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.collections.gaming.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Gaming
      steam
      steam-run
      lutris
      heroic # linux native Epic Games Launcher alternative
      #wine
      winetricks
      wineWowPackages.full
    ];
  };
}
