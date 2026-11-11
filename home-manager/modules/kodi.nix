{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  runHeadless = osConfig.custom.gui.headless;
  enable = !runHeadless && osConfig.custom.hm.modules.kodi.enable;
in
{
  config = lib.mkIf enable {
    programs.kodi = {
      enable = true;
      # binary addons can not be installed from within kodi on NixOS
      # inputstream-adaptive is required for DRM playback (amazon, netflix)
      # X11 build (runs via XWayland): the wayland build hands widevine decoded
      # frames over as DRM_PRIME, which its GL renderer can't display (black screen)
      package = pkgs.kodi.withPackages (kodiPkgs: [
        kodiPkgs.inputstream-adaptive
      ]);
    };
  };
}
