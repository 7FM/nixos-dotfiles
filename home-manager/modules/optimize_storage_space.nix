{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.modules.optimize_storage.enable;
in {
  config = lib.mkIf enable {
    programs.man.enable = false;
    manual.manpages.enable = false;
  };
}
