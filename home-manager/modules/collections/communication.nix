{ config, pkgs, lib, osConfig, ... }:

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

  wrappedMattermost = pkgs.writeShellScriptBin "mattermost-desktop" ''
    exec ${pkgs.mattermost-desktop}/bin/mattermost-desktop --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
  '';
  myMattermost = pkgs.symlinkJoin rec {
    inherit (pkgs.mattermost-desktop) name pname;

    paths = [
      wrappedMattermost
      pkgs.mattermost-desktop
    ];
  };

  enable = osConfig.custom.hm.collections.communication.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # Communication
      discord
      myMattermost
      myZoom
      teamspeak_client
    ];

    xdg.configFile."discord/settings.json".source = ../../configs/discord/settings.json;
  };
}
