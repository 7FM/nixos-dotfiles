{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  enable = config.custom.gpu == "intel";
in {
  config = lib.mkIf enable {
    hardware.graphics = {
      extraPackages = with pkgs; [
        vpl-gpu-rt
        intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
        #intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
        #intel-vaapi-driver
      ];
    };
  };
}

