{ config, pkgs, lib, ... }:

# Window system settings:
let
  runHeadless = config.custom.gui == "headless";
  myTools = pkgs.myTools { inherit config pkgs lib; };

  backendUsePulseaudio = true;
  backendUsePipewire = !backendUsePulseaudio;
in {

  config = lib.mkIf (!runHeadless) {
    # Common sound settings
    # rtkit is optional but recommended
    security.rtkit.enable = true;

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