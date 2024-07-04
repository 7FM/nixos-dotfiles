{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  enable = config.custom.gpu == "amd";
in {

  config = lib.mkIf enable {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.graphics.extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
      amdvlk
    ];
  };

}

