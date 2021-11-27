{ config, lib, pkgs, modulesPath, ... }:

let
  enable = config.custom.device == "desktop";
in {
  config.custom = lib.mkIf enable {
    # System settings
    gpu = "amd";
    cpu = "amd";
    # gui = "wayland";
    gui = "hm-wayland";
    useDummySecrets = false;
  };
}
