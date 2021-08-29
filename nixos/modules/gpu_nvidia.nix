{ config, pkgs, lib, ... }:

let
  enable = config.custom.gpu == "nvidia";


  # This creates a new 'nvidia-offload' program that runs the application passed to it on the GPU
  # As per https://nixos.wiki/wiki/Nvidia
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in {

  config = lib.mkIf enable {
    # nvidia gpu specific settings
    virtualisation.podman.enableNvidia = true;
    virtualisation.docker.enableNvidia = true;
    services.xserver.displayManager.gdm.nvidiaWayland = true;

    services.xserver.videoDrivers = [ "nvidia" ];
    environment.systemPackages = [ nvidia-offload ];

    hardware.nvidia.prime = {
      offload.enable = true;
      # Hardware should specify the bus ID for intel/nvidia devices
    };
  };

}

