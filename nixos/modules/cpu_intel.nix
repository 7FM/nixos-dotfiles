{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  enable = config.custom.cpu == "intel";
in {

  config = lib.mkIf enable {
    # Patch some issues via microcode
    hardware.cpu.intel.updateMicrocode = true;

    boot.initrd.kernelModules = [ "i915" ];

    hardware.graphics.extraPackages = with pkgs; [
      #vaapiIntel # already part of nixos-hardware, but differently configured
      vaapiVdpau
      libvdpau-va-gl
      intel-media-driver
    ];
  };
}

