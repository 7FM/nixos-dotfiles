{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  governor = config.custom.cpuFreqGovernor;
in {

  # Power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = governor;
  };

  hardware.bluetooth.powerOnBoot = false;
  networking.networkmanager.wifi.powersave = true;

  services.logind.lidSwitch = "lock";
  services.logind.lidSwitchExternalPower = "lock";
  services.logind.lidSwitchDocked = "ignore";

}

