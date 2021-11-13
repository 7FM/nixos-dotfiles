{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.alacritty.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      alacritty
    ];

    home.file.".config/alacritty/alacritty.yml".source = ../configs/terminal/alacritty.yml;
  };
}
