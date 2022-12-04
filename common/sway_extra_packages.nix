{ pkgs }:

with pkgs; [
  qt5.qtwayland

  #swaylock
  #swaylock-fancy
  swaylock-effects
  swayidle
  alacritty # gpu accelerated terminal emulator
  wofi # program launcher
  mpv # to play notification sounds

  xorg.xlsclients # Helper program to show programs running using xwayland
  xorg.xhost # can be used to allow Xwayland applications to run as root, i.e. gparted
  clipman # Clipboard manager
  wl-clipboard
  swaybg # TODO is this explicitly needed?

  wf-recorder # screen recording
  slurp # wayland region selector
  grim # wayland cli screenshot tool
  jq # json parser, needed for sway screensharing script
]
