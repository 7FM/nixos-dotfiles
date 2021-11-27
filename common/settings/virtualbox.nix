{ config, lib, pkgs, modulesPath, ... }:

let
  enable = config.custom.device == "virtualbox";
in {
  config.custom = lib.mkIf enable {
    # System settings
    gpu = "generic";
    cpu = "generic";
    gui = "wayland";
    useDummySecrets = true;
  };
}
