{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    # Utilities
    wget
    htop
    gparted
    nmap
    nmap-graphical
    x2goclient
    syncthing
  ];
}
