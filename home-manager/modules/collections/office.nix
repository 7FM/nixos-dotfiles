{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    # Some basic gui programs
    firefox
    thunderbird
    gimp
    vlc
    keepassxc
  ];
}
