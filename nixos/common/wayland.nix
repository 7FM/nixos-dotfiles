{ config, pkgs, lib, ... }:

let
  enable = config.custom.gui == "wayland";
in {

  config = lib.mkIf enable {

    services.xserver.displayManager.gdm.wayland = true;

    environment.systemPackages = with pkgs; [ qt5.qtwayland ];

    environment.sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      SDL_VIDEODRIVER = "wayland";
      XDG_SESSION_TYPE = "wayland";
      # QT needs qt5.qtwayland in systemPackages
      QT_QPA_PLATFORM = "wayland-egl";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };

    # Window system settings:
    # Wayland in the form of sway
    programs.sway.enable = true;
    environment.loginShellInit = lib.mkAfter ''[[ "$(tty)" == /dev/tty1 ]] && exec sway'';
    # Allow backwards compatibility for X programs
    programs.xwayland.enable = true;

    # Sway customization
    programs.sway = {
      wrapperFeatures.gtk = true; # so that gtk works pro>
      extraPackages = with pkgs; [
        swaylock
        swaylock-fancy
        swayidle
        wl-clipboard
        mako # notification daemon
        alacritty # Alacritty is the default terminal in >
        wofi # Dmenu is the default in the config but I r>
        waybar # Highly customizable wayland bar for sway>
        brightnessctl
        polkit_gnome # Service to bring up authentication>
        pavucontrol # GUI to control pulseaudio settings
        xorg.xlsclients # Helper program to show programs>
        clipman # Clipboard manager
        swaybg # TODO is this explicitly needed?
        wlogout # logout menu
      ];
    };

  };

}

