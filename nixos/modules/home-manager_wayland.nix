{ config, pkgs, lib, ... }:

let
  enable = config.custom.gui == "hm-wayland";
in {

  config = lib.mkIf enable {

    services.xserver.displayManager.gdm.wayland = true;

    security.pam.services.swaylock = {};
    programs.dconf.enable = true;

    # TODO check if this fixes the broken layout for sway on HM
    # Else try installing the same default fonts manually in HM
    fonts.enableDefaultFonts = true;

    # Enable support for screen sharing
    services.pipewire.enable = true;
    xdg.portal = {
      enable = true;
      gtkUsePortal = true;

      extraPortals = with pkgs; [
       xdg-desktop-portal-wlr
       xdg-desktop-portal-gtk
      ];
    };
  };

}
