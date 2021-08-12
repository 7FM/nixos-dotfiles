{ config, pkgs, lib, ... }:

{

  # overwrite the swap settings
  swapDevices = lib.mkForce [
    { 
      device = "/swapfile";
      priority = 10;
      size = 1024;
    }
  ];

}

