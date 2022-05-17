{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
  enable = config.custom.gui == "x11";
in {

  config = lib.mkIf enable {

    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.autorun = true;

    # Enable touchpad support (enabled default in most desktopManager).
    services.xserver.libinput = {
      enable = true;

      touchpad = {
        tapping = true;
        scrollMethod = "twofinger";
        naturalScrolling = true;
      };
    };

    # Display Manager: provides graphical login
    # NOTE: lightdm & sddm only supports X11
    #services.xserver.displayManager.lightdm.enable = true;
    #services.xserver.displayManager.sddm.enable = true;
    #services.xserver.displayManager.gdm.enable = true;
    services.xserver.displayManager.gdm.wayland = false;

    # Window manager
    #services.xserver.windowManager.xmonad.enable = true;
    #services.xserver.windowManager.twm.enable = true;
    #services.xserver.windowManager.icewm.enable = true;
    #services.xserver.windowManager.i3.enable = true;
    #services.xserver.windowManager.herbstluftwm.enable = true;

    # Desktop Environment
    services.xserver.desktopManager.gnome.enable = true;
    #services.xserver.desktopManager.xfce.enable = true;
    #services.xserver.desktopManager.plasma5.enable = true;
    #services.xserver.desktopManager.mate.enable = true;

    services.gnome.games.enable = false;
    services.gnome.core-utilities.enable = false;
    #environment.gnome.excludePackages = with pkgs [ gnome.cheese gnome-photos gnome-music gnome-gedit epiphany evince gnome-characters gnome.totem gnome.tali gnome.iagno gnome.hitori gnome.atomix gnome-tour ];
  };

}

