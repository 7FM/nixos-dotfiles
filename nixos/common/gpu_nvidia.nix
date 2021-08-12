{ config, pkgs, lib, ... }:

let
  enable = config.custom.gpu == "nvidia";
in {

  config = lib.mkIf enable {
    # nvidia gpu specific settings
    virtualisation.podman.enableNvidia = true;
    virtualisation.docker.enableNvidia = true;
    services.xserver.displayManager.gdm.nvidiaWayland = true;
  };

}

