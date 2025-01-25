{ config, pkgs, lib, ... }:

# Window system settings:
let
  runHeadless = config.custom.gui == "headless";
  myTools = pkgs.myTools { osConfig = config; };

  cfg = config.custom.audio;

  backendUsePulseaudio = cfg.backend == "pulseaudio";
  backendUsePipewire = cfg.backend == "pipewire";
  noBackend = cfg.backend == "none";
in {

  config = lib.mkIf (!runHeadless) {
    # Common sound settings
    # rtkit is optional but recommended
    security.rtkit.enable = !noBackend;

    # Enable sound via pulseaudio
    services.pulseaudio = {
      enable = backendUsePulseaudio;
      support32Bit = backendUsePulseaudio;
    };

    # Enable sound via pipewire
    services.pipewire = {
      enable = lib.mkDefault backendUsePipewire;
      alsa.enable = backendUsePipewire;
      alsa.support32Bit = backendUsePipewire;
      pulse.enable = backendUsePipewire;
      # If you want to use JACK applications, uncomment this
      #jack.enable = backendUsePipewire;
    };
  };
}
