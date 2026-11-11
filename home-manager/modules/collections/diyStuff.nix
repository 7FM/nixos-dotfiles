{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  enable = osConfig.custom.hm.collections.diyStuff.enable;
in
{
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # 3D Printing & DIY stuff
      freecad
      orca-slicer
      bambu-studio
    ];

    # FreeCAD helper macros
    xdg.dataFile = {
      "FreeCAD/Macro/rotate_and_duplicate.FCMacro".source =
        ../../configs/freecad/Macro/rotate_and_duplicate.FCMacro;
      "FreeCAD/Macro/spreadsheet_alias_to_left.FCMacro".source =
        ../../configs/freecad/Macro/spreadsheet_alias_to_left.FCMacro;
      "FreeCAD/Macro/show_all_constraints.FCMacro".source =
        ../../configs/freecad/Macro/show_all_constraints.FCMacro;
      "FreeCAD/Macro/hide_all_constraints.FCMacro".source =
        ../../configs/freecad/Macro/hide_all_constraints.FCMacro;
      "FreeCAD/Macro/hide_zero_constraints.FCMacro".source =
        ../../configs/freecad/Macro/hide_zero_constraints.FCMacro;
      "FreeCAD/Macro/hide_geometry_constraints.FCMacro".source =
        ../../configs/freecad/Macro/hide_geometry_constraints.FCMacro;
    };
  };
}
