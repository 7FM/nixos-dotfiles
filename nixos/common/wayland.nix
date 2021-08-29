{ config, pkgs, lib, ... }:

let
  enable = config.custom.gui == "wayland";

  autostartSway = false;

in {

  config = lib.mkIf enable {
    # Enable bluetooth manager when bluetooth is enabled
    services.blueman.enable = config.hardware.bluetooth.enable;

    # Add an overlay for sway to include apply some experimental patches
#    nixpkgs.overlays = [
#      (self: super: {
#        sway = super.sway.overrideAttrs (oldAttrs: {
#          patches = (oldAttrs.patches or []) ++ [
#            ../patches/sway.patch
#          ];
#        });
#      })
#    ];

    services.xserver.displayManager.gdm.wayland = true;

    environment.sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      SDL_VIDEODRIVER = "wayland";
      XDG_SESSION_TYPE = "wayland";
      # QT needs qt5.qtwayland in systemPackages
      QT_QPA_PLATFORM = "wayland-egl";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # Fix message: [wlr] [libseat] [libseat/backend/seatd.c:70] Could not connect to socket /run/seatd.sock: no such file or directory
      LIBSEAT_BACKEND = "logind";
    };


    # Window system settings:
    # Wayland in the form of sway
    programs.sway.enable = true;
    environment.loginShellInit = lib.optionalString autostartSway (lib.mkAfter ''[[ "$(tty)" == /dev/tty1 ]] && exec sway'');
    #environment.loginShellInit = lib.mkAfter ''[[ "$(tty)" == /dev/tty1 ]] && exec sway -d 2> ~/sway.log'';
    # Allow backwards compatibility for X programs
    programs.xwayland.enable = true;

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

    # Sway customization
    programs.sway = {
      wrapperFeatures.gtk = true; # so that gtk works pro>
      extraPackages = import ../../common/sway_extra_packages.nix;
    };

  };

}

