{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.collections.communication.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Communication
      discord
      #teamspeak_client
    ];

    xdg.configFile."discord/settings.json".source = ../../configs/discord/settings.json;
  };
}
