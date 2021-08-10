{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Utilities
    wget
    htop
    gparted
    #nmap
    nmap-graphical
    x2goclient
    syncthing
  ];
}
