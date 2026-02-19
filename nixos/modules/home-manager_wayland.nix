{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  enable = config.custom.gui == "hm-wayland";
in {

  config = lib.mkIf enable {
    # Enable bluetooth manager when bluetooth is enabled
    services.blueman.enable = config.hardware.bluetooth.enable;

    services.displayManager.gdm.wayland = true;
    services.displayManager.sessionPackages = with pkgs; [sway];
    services.displayManager.defaultSession = "sway";
    services.xserver.desktopManager.xterm.enable = false;

    services.displayManager.gdm.enable = false;

    # SDDM requirements
    services.displayManager.sddm = rec {
      enable = true;
      wayland.enable = enable;
    };
    services.libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        scrollMethod = "twofinger";
        naturalScrolling = true;
      };
    };

    # Ensure the keyrings are opened
    security.pam.services.sddm.enableGnomeKeyring = config.services.displayManager.sddm.enable;
    security.pam.services.gdm.enableGnomeKeyring = config.services.displayManager.gdm.enable;

    security.pam.services.swaylock = {};
    programs.dconf.enable = true;

    fonts = {
      enableDefaultPackages = true;
      fontconfig.enable = true;
      fontconfig.defaultFonts = {
        # serif = [ "MesloLGS Nerd Font" ];
        # sansSerif = [ "MesloLGS Nerd Font" ];
        # monospace = [ "MesloLGS Nerd Font Mono" ];
        serif = [ "DejaVu Serif" ];
        sansSerif = [ "DejaVu Sans" ];
        monospace = [ "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
      packages = with pkgs; [
        libertine
        libertinus
        noto-fonts
        noto-fonts-color-emoji
        nerd-fonts.meslo-lg
        google-fonts
      ];
    };

    # Enable support for screen sharing
    services.pipewire.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;

      extraPortals = with pkgs; [
       xdg-desktop-portal-gtk
      ];

      config.common.default = [
        "wlr"
        "gtk"
      ];
    };

    # Allow programs within sway to request real-time priorities
    security.pam.loginLimits = [
      { domain = "@users"; item = "rtprio"; type = "-"; value = 1; }
    ];
  };

}
