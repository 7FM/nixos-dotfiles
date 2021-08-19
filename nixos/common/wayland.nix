{ config, pkgs, lib, ... }:

let
  enable = config.custom.gui == "wayland";

  myPolkitGnome = pkgs.polkit_gnome.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      mkdir -p $out/bin
      ln -s $out/libexec/polkit-gnome-authentication-agent-1 $out/bin/polkit-gnome-authentication-agent-1
    '';
  });

in {

  config = lib.mkIf enable {

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

    environment.systemPackages = with pkgs; [ qt5.qtwayland ];

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
    environment.loginShellInit = lib.mkAfter ''[[ "$(tty)" == /dev/tty1 ]] && exec sway'';
    #environment.loginShellInit = lib.mkAfter ''[[ "$(tty)" == /dev/tty1 ]] && exec sway -d 2> ~/sway.log'';
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
        alacritty # gpu accelerated terminal emulator
        wofi # program launcher
        waybar # Highly customizable wayland bar for sway
        brightnessctl

        #polkit_gnome # Service to bring up authentication popups
        myPolkitGnome
        #lxqt.lxqt-policykit

        pavucontrol # GUI to control pulseaudio settings
        xorg.xlsclients # Helper program to show programs running using xwayland
        xorg.xhost # can be used to allow Xwayland applications to run as root, i.e. gparted
        clipman # Clipboard manager
        swaybg # TODO is this explicitly needed?
        wlogout # logout menu
        networkmanagerapplet # NetworkManager Front-End
      ];
    };

  };

}

