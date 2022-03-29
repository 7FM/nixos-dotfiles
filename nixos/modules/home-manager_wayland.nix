{ config, pkgs, lib, ... }:

let
  enable = config.custom.gui == "hm-wayland";
in {

  config = lib.mkIf enable {
    # Enable bluetooth manager when bluetooth is enabled
    services.blueman.enable = config.hardware.bluetooth.enable;

    services.xserver.displayManager.gdm.wayland = true;
    services.xserver.displayManager.sessionPackages = with pkgs; [sway];
    services.xserver.displayManager.defaultSession = "sway";

    # SDDM requirements
    services.xserver.displayManager.sddm.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
    services.xserver = {
      enable = true;
      libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          scrollMethod = "twofinger";
          naturalScrolling = true;
        };
      };
    };

    security.pam.services.swaylock = {};
    programs.dconf.enable = true;

    # TODO check if this fixes the broken layout for sway on HM
    # Else try installing the same default fonts manually in HM
    fonts.enableDefaultFonts = true;

    # Enable support for screen sharing
    services.pipewire.enable = true;
    xdg.portal = {
      enable = true;
      wlr = {
        enable = true;
      };
      gtkUsePortal = true;

      extraPortals = with pkgs; [
       xdg-desktop-portal-gtk
      ];
    };
  };

}
