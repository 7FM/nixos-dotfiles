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
  # 1. check required nss version: nix path-info $(which firefox) -r | grep nss-
  # 2. find correct package: https://search.nixos.org/packages/?query=nss_
  # 3. update nss package below
  myDiscord = pkgs.discord;
  #myDiscord = pkgs.discord.override {
  #  nss = pkgs.nss_latest;
  #};

  enable = config.custom.hm.collections.communication.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Communication
      myDiscord
      mattermost-desktop
      myZoom
      teamspeak_client
    ];

    xdg.configFile."discord/settings.json".source = ../../configs/discord/settings.json;
  };
}
