{ config, lib, pkgs, modulesPath, ... }:

{
  custom = {
    # System settings
    gpu = "generic";
    cpu = "generic";
    gui = "wayland";
    useDummySecrets = true;
  };
}
