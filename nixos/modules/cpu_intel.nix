{ config, pkgs, lib, ... }:

let
  enable = config.custom.cpu == "intel";
in {

  config = lib.mkIf enable {
    # Patch some issues via microcode
    hardware.cpu.intel.updateMicrocode = true;

    boot.initrd.kernelModules = [ "i915" ];

    hardware.opengl.extraPackages = with pkgs; [
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-media-driver
    ];
  };
}

