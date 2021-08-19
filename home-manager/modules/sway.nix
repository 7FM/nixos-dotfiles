{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # needed for waybar customization
    font-awesome
  ];

  # This enables discovering fonts that where installed with home.packages
  fonts.fontconfig.enable = true;

  home.file.".config/sway".source = ../configs/sway;
  home.file.".config/wofi".source = ../configs/wofi;
  home.file.".config/waybar".source = ../configs/waybar;
  home.file.".config/wlogout".source = ../configs/wlogout;
}
