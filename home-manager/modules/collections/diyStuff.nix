{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.collections.diyStuff.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      # 3D Printing & DIY stuff
      # Cura does not build: https://github.com/NixOS/nixpkgs/issues/325896
      #cura
      #nur.repos.xeals.cura5 #TODO waiting for update & https://github.com/xeals/nur-packages/pull/76
      (let cura5 = appimageTools.wrapType2 rec {
        name = "cura5";
        version = "5.7.2";
        src = let
          tagName = "${version}-RC2";
        in fetchurl {
          url = "https://github.com/Ultimaker/Cura/releases/download/${tagName}/UltiMaker-Cura-${version}-linux-X64.AppImage";
          hash = "sha256-XlTcCmIqcfTg8fxM2KDik66qjIKktWet+94lFIJWopY=";
        };
        extraPkgs = pkgs: with pkgs; [ ];
      }; in writeScriptBin "cura" ''
        #! ${pkgs.bash}/bin/bash
        # AppImage version of Cura loses current working directory and treats all paths relateive to $HOME.
        # So we convert each of the files passed as argument to an absolute path.
        # This fixes use cases like `cd /path/to/my/files; cura mymodel.stl anothermodel.stl`.
        args=()
        for a in "$@"; do
          if [ -e "$a" ]; then
            a="$(realpath "$a")"
          fi
          args+=("$a")
        done
        QT_QPA_PLATFORM=xcb exec "${cura5}/bin/cura5" "''${args[@]}"
      '')
      # TODO waiting for: https://nixpk.gs/pr-tracker.html?pr=362194
      #super-slicer-latest
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

      # Remove image mime types from cura
      mimeApps.associations.removed = {
        "image/bmp" = "com.ultimaker.cura.desktop";
        "image/gif" = "com.ultimaker.cura.desktop";
        "image/jpeg" = "com.ultimaker.cura.desktop";
        "image/png" = "com.ultimaker.cura.desktop";
      };

      # SuperSlicer settings/profiles
      configFile."SuperSlicer/filament".source = ../../configs/SuperSlicer/filament;
      configFile."SuperSlicer/print".source = ../../configs/SuperSlicer/print;
      configFile."SuperSlicer/printer".source = ../../configs/SuperSlicer/printer;

      # FreeCAD helper macros
      dataFile."FreeCAD/Macro/rotate_and_duplicate.FCMacro".source = ../../configs/freecad/Macro/rotate_and_duplicate.FCMacro;
      dataFile."FreeCAD/Macro/spreadsheet_alias_to_left.FCMacro".source = ../../configs/freecad/Macro/spreadsheet_alias_to_left.FCMacro;
      dataFile."FreeCAD/Macro/show_all_constraints.FCMacro".source = ../../configs/freecad/Macro/show_all_constraints.FCMacro;
      dataFile."FreeCAD/Macro/hide_all_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_all_constraints.FCMacro;
      dataFile."FreeCAD/Macro/hide_zero_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_zero_constraints.FCMacro;
      dataFile."FreeCAD/Macro/hide_geometry_constraints.FCMacro".source = ../../configs/freecad/Macro/hide_geometry_constraints.FCMacro;
    };
  };
}
