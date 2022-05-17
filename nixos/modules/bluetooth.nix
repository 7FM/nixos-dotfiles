{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
  enable = config.custom.bluetooth;
in {

  config = lib.mkIf enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

}

