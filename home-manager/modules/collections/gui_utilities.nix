{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
  enable = config.custom.hm.collections.gui_utilities.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Utilities
      gparted
      nmap-graphical
      syncthing
      openconnect
      x2goclient
      idasen # Python API and CLI for the ikea IDÅSEN desk
    ];

    # Config for idasen
    xdg.configFile."idasen".source = myTools.getSecretPath ../../configs "idasen";
  };
}
