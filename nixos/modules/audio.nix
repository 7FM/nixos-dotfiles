{ config, pkgs, lib, ... }:

# Window system settings:
let
  runHeadless = config.custom.gui == "headless";
  myTools = pkgs.myTools { inherit config pkgs lib; };

  cfg = config.custom.audio;

  backendUsePulseaudio = cfg.backend == "pulseaudio";
  backendUsePipewire = cfg.backend == "pipewire";
  noBackend = cfg.backend == "none";
in {
  options.custom.audio = with lib; {

    backend = mkOption {
      type = types.enum [ "none" "pulseaudio" "pipewire" ];
      default = "pulseaudio";
      description = ''
        Specifies the audio backend to use.
      '';
    };

  };

  config = lib.mkIf (!runHeadless) {
    # Common sound settings
    # rtkit is optional but recommended
    security.rtkit.enable = !noBackend;

    # Enable sound via pulseaudio
    sound.enable = backendUsePulseaudio;
    hardware.pulseaudio = {
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

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = backendUsePipewire;
    };
    # Install the pulseaudio package to still have access to pactl
    environment.systemPackages = with pkgs; lib.optionals backendUsePipewire [ pulseaudio ];
  };
}