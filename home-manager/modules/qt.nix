{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  enable = osConfig.custom.hm.modules.qt.enable;
in
{
  config = lib.mkIf enable {
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style = {
        name = "adwaita-dark";
        # Qt5 and Qt6 need separate style plugins
        package = [
          pkgs.adwaita-qt
          pkgs.adwaita-qt6
        ];
      };
    };
  };
}
