{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.bash.enable;
in {
  config = lib.mkIf enable {
    # ensure proper HM integration
    programs.bash.enable = true;
  };
}
