{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
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

