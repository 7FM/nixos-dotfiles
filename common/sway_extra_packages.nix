{ pkgs }:

with pkgs; [
  qt5.qtwayland

  alacritty # gpu accelerated terminal emulator

  xorg.xlsclients # Helper program to show programs running using xwayland
  xorg.xhost # can be used to allow Xwayland applications to run as root, i.e. gparted
  wl-clipboard
]
