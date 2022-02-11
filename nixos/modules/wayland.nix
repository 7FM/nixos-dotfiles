{ config, pkgs, lib, ... }:

let
  enable = config.custom.gui == "wayland";
in {

  config = lib.mkIf enable {
    # Enable bluetooth manager when bluetooth is enabled
    services.blueman.enable = config.hardware.bluetooth.enable;

    services.xserver.displayManager.gdm.wayland = true;
    services.xserver.displayManager.sessionPackages = with pkgs; [sway];

    # Window system settings:
    # Wayland in the form of sway
    programs.sway.enable = true;
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
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraSessionCommands = import ../../common/sway_extra_session_commands.nix;
      extraPackages = import ../../common/sway_extra_packages.nix { inherit pkgs; };
    };

  };

}

