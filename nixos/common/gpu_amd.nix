{ config, pkgs, lib, ... }:

let
  enable = config.custom.gpu == "amd";
in {

  config = lib.mkIf enable {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.opengl.extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
      amdvlk
    ];
  };

}

