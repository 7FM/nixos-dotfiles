{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    # Communication
    discord
    mattermost
    zoom-us
    teamspeak_client
  ];
}
