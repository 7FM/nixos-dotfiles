{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    # Gaming
    steam
    steam-run
    lutris-unwrapped
    wine
    winetricks
    wineWowPackages.full
  ];
}
