let
  myPolkitGnome = pkgs.polkit_gnome.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      mkdir -p $out/bin
      ln -s $out/libexec/polkit-gnome-authentication-agent-1 $out/bin/polkit-gnome-authentication-agent-1
    '';
  });
in with pkgs; [
  qt5.qtwayland

  swaylock
  swaylock-fancy
  swayidle
  mako # notification daemon
  alacritty # gpu accelerated terminal emulator
  wofi # program launcher
  waybar # Highly customizable wayland bar for sway
  brightnessctl

  #polkit_gnome # Service to bring up authentication popups
  myPolkitGnome

  pavucontrol # GUI to control pulseaudio settings
  xorg.xlsclients # Helper program to show programs running using xwayland
  xorg.xhost # can be used to allow Xwayland applications to run as root, i.e. gparted
  clipman # Clipboard manager
  wl-clipboard
  swaybg # TODO is this explicitly needed?
  wlogout # logout menu
  networkmanagerapplet # NetworkManager Front-End
]
