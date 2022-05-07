{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.xdg.enable;
in {
  config = lib.mkIf enable {
    xdg = {
      enable = true; # This sets environment variables such as: XDG_CACHE_HOME, XDG_CONFIG_HOME and XDG_DATA_HOME
      mimeApps.enable = true; # manage $XDG_CONFIG_HOME/mimeapps.list
    };
  };
}
