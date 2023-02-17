{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  enable = config.custom.bluetooth;
in {

  config = lib.mkIf enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
      package = pkgs.bluez5-experimental;
      settings.General.Experimental = true;
    };
  };

}

