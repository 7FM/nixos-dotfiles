{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  enable = config.custom.cpu == "amd";
in {

  # Patch some issues via microcode
  hardware.cpu.amd.updateMicrocode = enable;

}

