{ config, pkgs, lib, ... }:

let
  enable = config.custom.adb != "disabled";
  global = config.custom.adb == "global";
in {

  config = lib.mkIf enable (lib.mkMerge [
    {
      users.users.tm.extraGroups = ["adbusers"];
    }
    (lib.mkIf global {
      programs.adb.enable = true;
    })
    (lib.mkIf (!global) {
      services.udev.packages = [
        pkgs.android-udev-rules
      ];
    })
  ]);
}

