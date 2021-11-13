{ config, pkgs, lib, ... }:

let
  cfg = config.custom.swapfile;

  useSwapFile = cfg.enable;
  swapFileSize = cfg.size;
  swapFilePath = cfg.path;
in {

  options.custom.swapfile = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Specifies whether a swap file should used instead of a swap partition.
      '';
    };

    size = mkOption {
      type = types.ints.positive;
      default = 20 * 1024;
      description = ''
        Specifies the swap file size in MiB.
      '';
    };

    path = mkOption {
      type = types.str;
      default = "/swapfile";
      description = ''
        Specifies the swap file path.
      '';
    };
  };

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

