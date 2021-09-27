{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # 3D Printing & DIY stuff
    cura
    freecad
    openscad
    kicad
  ];

  home.file.".config/cura/baseSettings".source = ../../configs/cura/config;
  home.file.".local/share/cura/baseSettings".source = ../../configs/cura/local;
}
