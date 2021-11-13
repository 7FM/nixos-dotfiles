{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.gtk.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Install compatible icon theme for Lutris, gtkwave, etc.
      gnome3.adwaita-icon-theme
    ];

    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };
}
