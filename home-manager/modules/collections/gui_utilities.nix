{ config, pkgs, lib, osConfig, ... }:

let
  myTools = pkgs.myTools { inherit osConfig; };
  enable = osConfig.custom.hm.collections.gui_utilities.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Utilities
      gparted
      syncthing
      x2goclient
      idasen # Python API and CLI for the ikea IDÅSEN desk
    ];

    # Config for idasen
    xdg.configFile."idasen".source = myTools.getSecretPath ../../configs "idasen";
  };
}
