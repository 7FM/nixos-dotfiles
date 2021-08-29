{ config, pkgs, lib, ... }:

let
  enable = config.custom.cpu == "amd";
in {

  # Patch some issues via microcode
  hardware.cpu.amd.updateMicrocode = enable;

}

