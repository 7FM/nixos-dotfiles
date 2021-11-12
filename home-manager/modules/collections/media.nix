{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.collections.media.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # media playback tools
      vlc
      spotify
      playerctl # playback control
    ];
  };
}
