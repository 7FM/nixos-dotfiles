{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.modules.gtk.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Install compatible icon theme for Lutris, gtkwave, etc.
      adwaita-icon-theme
    ];

    gtk = {
      enable = true;
      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
        # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland#removing-the-rounded-corners-and-dropshadow-of-themes-like-adwaita
        extraCss = ''
          /** Some apps use titlebar class and some window */
          .titlebar,
          window {
            border-radius: 0;
            box-shadow: none;
          }

          /** also remove shadows */
          decoration {
            box-shadow: none;
          }

          decoration:backdrop {
            box-shadow: none;
          }
        '';
      };
    };
  };
}
