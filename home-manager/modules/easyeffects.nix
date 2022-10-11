{ config, pkgs, lib, ... }:

let
  runHeadless = config.custom.gui == "headless";
  cfg = config.custom.audio;
  backendUsePipewire = cfg.backend == "pipewire";

  enable = !runHeadless && backendUsePipewire && config.custom.hm.modules.easyeffects.enable;
in {
  config = lib.mkIf enable {
    services.easyeffects = {
      enable = true;
      presets = ""; #TODO
    };

    #TODO set preset configs
  };
}
