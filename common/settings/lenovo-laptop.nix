{ config, lib, pkgs, modulesPath, ... }:

{
  custom = {
    # System settings
    gpu = "intel";
    cpu = "intel";
    # gui = "wayland";
    gui = "hm-wayland";
    useDummySecrets = false;
    bluetooth = true;
    audio.backend = "pipewire";
  };
}
