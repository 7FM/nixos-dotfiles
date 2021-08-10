{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Communication
    discord
    mattermost
    zoom-us
    teamspeak_client
  ];
}
