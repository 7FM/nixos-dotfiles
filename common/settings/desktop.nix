{ config, lib, pkgs, modulesPath, ... }:

{
  custom = {
    # System settings
    gpu = "amd";
    cpu = "amd";
    # gui = "wayland";
    gui = "hm-wayland";
    useDummySecrets = false;
    bluetooth = true;
    audio.backend = "pipewire";
  };
}
