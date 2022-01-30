{ config, pkgs, lib, ... }:

let
  enable = config.custom.smartcards;
in {
  config = lib.mkIf enable {
    # Enable smartcard reader support
    services.pcscd.enable = true;
    services.pcscd.plugins = with pkgs; [
      ccid
      pcsc-cyberjack
    ];
  };
}

