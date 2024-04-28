{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.modules.qt.enable;
in {
  config = lib.mkIf enable {
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
