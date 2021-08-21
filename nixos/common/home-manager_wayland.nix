{ config, pkgs, lib, ... }:

let
  enable = config.custom.gui == "hm-wayland";
in {

  config = lib.mkIf enable {

    services.xserver.displayManager.gdm.wayland = true;

    #environment.systemPackages = with pkgs; [ qt5.qtwayland ];

    # Window system settings:
    # Wayland in the form of sway
    #programs.sway.enable = true;
    #environment.loginShellInit = lib.mkAfter ''[[ "$(tty)" == /dev/tty1 ]] && exec sway'';
    #environment.loginShellInit = lib.mkAfter ''[[ "$(tty)" == /dev/tty1 ]] && exec sway -d 2> ~/sway.log'';

    security.pam.services.swaylock = {};
    fonts.enableDefaultFonts = true;
    programs.dconf.enable = true;

    # Enable support for screen sharing
    xdg.portal.enable = true;
    services.pipewire.enable = true;
    xdg.portal.gtkUsePortal = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

}

