{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.qt.enable;
in {
  config = lib.mkIf enable {
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
