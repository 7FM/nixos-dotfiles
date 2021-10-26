{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # media playback tools
    vlc
    spotify
    playerctl # playback control
  ];
}
