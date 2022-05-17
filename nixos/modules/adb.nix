userName:
{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
  enable = config.custom.adb != "disabled";
  global = config.custom.adb == "global";
in {

  config = lib.mkIf enable (lib.mkMerge [
    {
      users.users."${userName}".extraGroups = ["adbusers"];
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

