{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    alacritty
  ];

  home.file.".config/alacritty/alacritty.yml".source = ../configs/terminal/alacritty.yml;
}
