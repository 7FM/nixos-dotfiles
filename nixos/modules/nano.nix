{ config, pkgs, lib, ... }:

let
  enable = config.custom.nano_conf.enable;
in {
  config = lib.mkIf enable {
    programs.nano = {
      nanorc = ''
        set tabstospaces
        set tabsize 2
        set constantshow
      '';
      syntaxHighlight = true;
    };
  };
}

