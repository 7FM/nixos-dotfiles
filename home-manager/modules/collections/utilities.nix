{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Utilities
    wget
    htop
    gparted
    zip
    unzip
    sxiv # Image viewer
    nnn # CLI file browser
    moc # CLI audio player
    unixtools.xxd # hexeditor
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

  # Plugins for nnn
  home.file.".config/nnn/plugins".source = ../../configs/nnn/plugins;
  # Enable certain plugins
  home.sessionVariables = {
    NNN_PLUG = "v:imgview;q:mocq;e:suedit;c:rsynccp;x:!chmod +x $nnn;h:hexview";
  };
}
