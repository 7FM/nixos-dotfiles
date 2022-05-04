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

    xdg = let 
      setupScript = ''
      #!/bin/sh

      if [ "$#" -ne 1 ]; then
        echo "Usage: $0 curaVersion" >&2
        exit 1
      fi

      curaVersion=$(echo "$1" | grep -Po '\d+.\d+')

      cd ${config.xdg.configHome}/cura
      mkdir -p $curaVersion
      cp -r baseSettings/* $curaVersion/
      find $curaVersion -type f -exec chmod 644 {} \;
      find $curaVersion -type d -exec chmod 755 {} \;

      cd ${config.xdg.dataHome}/cura
      mkdir -p $curaVersion
      cp -r baseSettings/* $curaVersion/
      find $curaVersion -type f -exec chmod 644 {} \;
      find $curaVersion -type d -exec chmod 755 {} \;
      '';
    in {
      configFile."cura/setup.sh" = {
        text = setupScript;
        executable = true;
      };
      dataFile."cura/setup.sh" = {
        text = setupScript;
        executable = true;
      };

      # Cura base configuration: you will need to copy these folders to the current version
      # If we would simlink this directly to an version number then no changes are possible, which we want for slicing!
      configFile."cura/baseSettings" = {
        # TODO can we also run this when a new cura version is used?
        source = ../../configs/cura/config;
        onChange = ''
          ${config.xdg.configHome}/cura/setup.sh ${pkgs.cura.version}
        '';
      };
      dataFile."cura/baseSettings".source = ../../configs/cura/local;
    };

    # FreeCAD helper macros
    home.file.".FreeCAD/Macro/rotate_and_duplicate.FCMacro".source = ../../configs/freecad/Macro/rotate_and_duplicate.FCMacro;
    home.file.".FreeCAD/Macro/spreadsheet_alias_to_left.FCMacro".source = ../../configs/freecad/Macro/spreadsheet_alias_to_left.FCMacro;
    home.file.".FreeCAD/Macro/show_all_constraints.FCMacro".source = ../../configs/freecad/Macro/show_all_constraints.FCMacro;
    home.file.".FreeCAD/Macro/hide_all_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_all_constraints.FCMacro;
    home.file.".FreeCAD/Macro/hide_zero_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_zero_constraints.FCMacro;
    home.file.".FreeCAD/Macro/hide_geometry_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_geometry_constraints.FCMacro;
  };
}
