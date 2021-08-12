{ config, pkgs, lib, ... }:

let
  enable = config.custom.cpu == "intel";
in {

  # Patch some issues via microcode
  hardware.cpu.intel.updateMicrocode = enable;

}

