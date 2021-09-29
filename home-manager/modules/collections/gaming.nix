{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Gaming
    steam
    steam-run
    lutris
    #wine
    winetricks
    wineWowPackages.full
  ];
}
