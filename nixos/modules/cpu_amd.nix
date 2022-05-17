{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
  enable = config.custom.cpu == "amd";
in {

  # Patch some issues via microcode
  hardware.cpu.amd.updateMicrocode = enable;

}

