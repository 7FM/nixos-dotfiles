{ config, pkgs, lib, ... }:

let

  # Wayland screen sharing fix up!
  # https://github.com/NixOS/nixpkgs/issues/107233
  # ALSO: ensure that in ~/.config/zoomus.conf 'enableWaylandShare=true' is set https://github.com/NixOS/nixpkgs/issues/107233#issuecomment-757424877
  myZoom = pkgs.zoom-us.overrideAttrs (old: {
    postFixup = old.postFixup + ''
      wrapProgram $out/bin/zoom-us --unset XDG_SESSION_TYPE
      wrapProgram $out/bin/zoom --unset XDG_SESSION_TYPE
    '';
  });

  # https://nixos.wiki/wiki/Discord
  # Fix opening links with firefox
  myDiscord = pkgs.discord.override {
    nss = pkgs.nss_latest;
  };

in {
  home.packages = with pkgs; [
    # Communication
    #discord
    myDiscord
    mattermost-desktop
    #zoom-us
    myZoom
    teamspeak_client
  ];

  home.file.".config/discord/settings.json".source = ../../configs/discord/settings.json;

}
