{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.optimize_storage.enable;
in {
  config = lib.mkIf enable {
    programs.man.enable = false;
    manual.manpages.enable = false;
  };
}
