{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Utilities
    wget
    htop
    gparted
    zip
    unzip
    #nmap
    nmap-graphical
    x2goclient
    syncthing
    speedtest-cli
    usbutils
    pciutils
  ];

  # Config for htop
  home.file.".config/htop".source = ../../configs/htop;
}
