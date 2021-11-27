{ config, lib, pkgs, modulesPath, ... }:

let
  enable = config.custom.device == "lenovo-laptop";
in {
  config.custom = lib.mkIf enable {
    # System settings
    gpu = "intel";
    cpu = "intel";
    # gui = "wayland";
    gui = "hm-wayland";
    useDummySecrets = false;
  };
}
