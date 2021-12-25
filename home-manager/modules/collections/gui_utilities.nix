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
      openconnect
      openvpn
      #x2goclient # Segfaults on wayland...
      (callPackage ../submodule/x2go-wayland-wrapper.nix {}) # This wrapper forces QT to use xwayland instead!
      idasen # Python API and CLI for the ikea IDÅSEN desk
    ];

    # Config for idasen
    xdg.configFile."idasen".source = myTools.getSecretPath ../../configs "idasen";
  };
}
