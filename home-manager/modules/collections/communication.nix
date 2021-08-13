{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Communication
    discord
    mattermost-desktop
    zoom-us
    teamspeak_client
  ];
}
