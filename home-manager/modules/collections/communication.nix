{ config, pkgs, lib, ... }:

let

 # Wayland screen sharing fix up!
 myZoom = pkgs.zoom-us.overrideAttrs (old: {
   postFixup = old.postFixup + ''
     wrapProgram $out/bin/zoom-us --unset XDG_SESSION_TYPE
     wrapProgram $out/bin/zoom --unset XDG_SESSION_TYPE
   '';
 });

in {
  home.packages = with pkgs; [
    # Communication
    discord
    mattermost-desktop
    #zoom-us
    myZoom
    teamspeak_client
  ];
}
