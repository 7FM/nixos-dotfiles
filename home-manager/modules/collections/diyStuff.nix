{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.collections.diyStuff.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # 3D Printing & DIY stuff
      cura
      freecad
      openscad
      kicad
    ];

    # Cura base configuration: you will need to copy these folders to the current version
    # If we would simlink this directly to an version number then no changes are possible, which we want for slicing!
    xdg.configFile."cura/baseSettings".source = ../../configs/cura/config;
    xdg.dataFile."cura/baseSettings".source = ../../configs/cura/local;

    # FreeCAD helper macros
    home.file.".FreeCAD/Macro/rotate_and_duplicate.FCMacro".source = ../../configs/freecad/Macro/rotate_and_duplicate.FCMacro;
    home.file.".FreeCAD/Macro/spreadsheet_alias_to_left.FCMacro".source = ../../configs/freecad/Macro/spreadsheet_alias_to_left.FCMacro;
    home.file.".FreeCAD/Macro/show_all_constraints.FCMacro".source = ../../configs/freecad/Macro/show_all_constraints.FCMacro;
    home.file.".FreeCAD/Macro/hide_all_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_all_constraints.FCMacro;
    home.file.".FreeCAD/Macro/hide_zero_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_zero_constraints.FCMacro;
    home.file.".FreeCAD/Macro/hide_geometry_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_geometry_constraints.FCMacro;
  };
}
