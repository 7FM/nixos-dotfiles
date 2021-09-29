{ config, pkgs, lib, ... }:

{

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

}
