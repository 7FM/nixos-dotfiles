{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    # 3D Printing & DIY stuff
    cura
    freecad
    openscad
    kicad
  ];
}
