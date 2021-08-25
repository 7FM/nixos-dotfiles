{ config, pkgs, lib, ... }:

let
  enable = config.custom.bluetooth;
in {

  config = lib.mkIf enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

}

