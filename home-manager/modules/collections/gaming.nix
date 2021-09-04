{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Gaming
    steam
    steam-run
    lutris
    # Install compatible icon theme for Lutris
    gnome3.adwaita-icon-theme
    #wine
    winetricks
    wineWowPackages.full
  ];
}
