{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # 3D Printing & DIY stuff
    cura
    freecad
    openscad
    kicad
  ];

  # Cura base configuration: you will need to copy these folders to the current version
  # If we would simlink this directly to an version number then no changes are possible, which we want for slicing!
  home.file.".config/cura/baseSettings".source = ../../configs/cura/config;
  home.file.".local/share/cura/baseSettings".source = ../../configs/cura/local;

  # FreeCAD helper macros
  home.file.".FreeCAD/Macro/rotate_and_duplicate.FCMacro".source = ../../configs/freecad/Macro/rotate_and_duplicate.FCMacro;
  home.file.".FreeCAD/Macro/spreadsheet_alias_to_left.FCMacro".source = ../../configs/freecad/Macro/spreadsheet_alias_to_left.FCMacro;
}
