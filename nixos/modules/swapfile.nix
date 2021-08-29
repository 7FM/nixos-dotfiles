{ config, pkgs, lib, ... }:

let
  useSwapFile = config.custom.useSwapFile;
  swapFileSize = config.custom.swapFileSize;
  swapFilePath = config.custom.swapFilePath;
in {

  config = lib.mkIf useSwapFile {
    # overwrite the swap settings
    swapDevices = lib.mkForce [
      {
        device = swapFilePath;
        priority = 10;
        size = swapFileSize;
      }
    ];
  };
}

