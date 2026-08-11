{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  enable = osConfig.custom.hm.modules.gtk.enable;
in
{
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Install compatible icon theme for Lutris, gtkwave, etc.
      adwaita-icon-theme
    ];

    gtk = {
      enable = true;

      gtk4.theme = null;

      # Was `nordic`, dropped from nixpkgs along with every other theme that
      # depended on the GTK2-only gtk-engine-murrine. Colloid's `nord` tweak is
      # the closest surviving match to the old Nord palette.
      theme = {
        name = "Colloid-Dark-Nord";
        package = pkgs.colloid-gtk-theme.override {
          colorVariants = [ "dark" ];
          tweaks = [ "nord" ];
        };
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

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
