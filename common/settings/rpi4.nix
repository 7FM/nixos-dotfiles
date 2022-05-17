{ config, lib, pkgs, modulesPath, ... }:

{
  custom = {
    # System settings
    gpu = "generic";
    cpu = "generic";
    gui = "headless";
    useDummySecrets = false;
    bluetooth = false;
  };
}
