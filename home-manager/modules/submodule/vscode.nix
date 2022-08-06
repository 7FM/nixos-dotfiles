{ config, pkgs, lib, ... }:

let
  useClangd = false;
  usePlatformIO = true;

  vsExtensions = with pkgs.vscode-extensions; [
      # Nix language support
      bbenoist.nix
      # Nix env selector
      arrterian.nix-env-selector

      # Live share
      ms-vsliveshare.vsliveshare
      # C++
      (if useClangd then llvm-vs-code-extensions.vscode-clangd else ms-vscode.cpptools)

      # Rust
      matklad.rust-analyzer
      # Python
      ms-python.python
      ms-python.vscode-pylance
      ms-toolsai.jupyter
      # Java
      redhat.java
      # Scala
      scala-lang.scala
      scalameta.metals
      # XML
      dotjoshjohnson.xml
    ] ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace ([
      # RUN $ ./pkgs/applications/editors/vscode/extensions/update_installed_exts.sh > extensions.nix
      # To update the extensions!

      #ms-vscode.cmake-tools
      #{
      #  name = "cmake-tools";
      #  publisher = "ms-vscode";
      #  version = "1.9.2";
      #  sha256 = "sha256-egikoFQCLEc8sy01KduqXrEbIZQKPK03CxijkR0wI4s=";
      #}
      #xaver.clang-format
      # {
      #   name = "clang-format";
      #   publisher = "xaver";
      #   version = "1.9.0";
      #   sha256 = "sha256-q9DvkXbv+GTyeMVIyUQDK49Njsl9msbnOD1gyS4ljC8=";
      # }
      #ms-vscode.hexeditor
      {
        name = "hexeditor";
        publisher = "ms-vscode";
        version = "1.9.7";
        sha256 = "1hv0am6y4d4dggq8viw4f5x6mavah11dqrrxa15lwm2a5ias93xx";
      }
      #ms-vscode.notepadplusplus-keybindings
      {
        name = "notepadplusplus-keybindings";
        publisher = "ms-vscode";
        version = "1.0.7";
        sha256 = "sha256-iC/jJhor3+Z2Tfes/4K0dYG012fdIec18/JguqX5FZE=";
      }
      #wayou.vscode-todo-highlight
      {
        name = "vscode-todo-highlight";
        publisher = "wayou";
        version = "1.0.5";
        sha256 = "sha256-CQVtMdt/fZcNIbH/KybJixnLqCsz5iF1U0k+GfL65Ok=";
      }
      #webfreak.debug
      {
        name = "debug";
        publisher = "webfreak";
        version = "0.26.0";
        sha256 = "0rsxnjcs4imd3kj01g2k92xv4vr48rs0zb6x9jcg7vr64yry0nk4";
      }
      #visualstudioexptteam.vscodeintellicode
      {
        name = "vscodeintellicode";
        publisher = "VisualStudioExptTeam";
        version = "1.2.21";
        sha256 = "17sk2zwl2qmcvyajvgvzx22hzxrv0bal5qs7jwih573f3q124dnv";
      }

      # Spelling
      #streetsidesoftware.code-spell-checker
      {
        name = "code-spell-checker";
        publisher = "streetsidesoftware";
        version = "2.2.5";
        sha256 = "0ayhlzh3b2mcdx6mdj00y4qxvv6mirfpnp8q5zvidm6sv3vwlcj0";
      }
      #streetsidesoftware.code-spell-checker-german
      {
        name = "code-spell-checker-german";
        publisher = "streetsidesoftware";
        version = "2.0.4";
        sha256 = "14m2kab12hjp4b81dz88vmg42czika8jp0c5qn5x4abmv0i0zika";
      }

      # Language support
      # llvm-vs-code-extensions.vscode-mlir
      {
        name = "vscode-mlir";
        publisher = "llvm-vs-code-extensions";
        version = "0.0.9";
        sha256 = "0cz4vwgyvb7714gvxzrh3k0dzrvvdzyzrypfn2ivqmcxsaclgl4y";
      }
      #antyos.openscad
      {
        name = "openscad";
        publisher = "antyos";
        version = "1.1.1";
        sha256 = "sha256-W942+PBR2ZQROVSm24smLIlCRZTPUUsNHfPaIWXirKk=";
      }
      #bkromhout.vscode-tcl
      {
        name = "vscode-tcl";
        publisher = "bkromhout";
        version = "0.2.0";
        sha256 = "sha256-9CnnIkfVGyGzmVEwQzFv/HlJXMzX3GuASZ6VGF3OaPA=";
      }
      #eirikpre.systemverilog
      {
        name = "systemverilog";
        publisher = "eirikpre";
        version = "0.13.2";
        sha256 = "0cxklipfm9whwljyxdyzrw590lanhq7ikv0s4wi294y4vffbgmy2";
      }
      #mshr-h.veriloghdl
      {
        name = "veriloghdl";
        publisher = "mshr-h";
        version = "1.5.4";
        sha256 = "1i8qcfx5v4d30gkyy00a4d8l6ss828va6lp69h9i1ynrgqzl85av";
      }
      #torn4dom4n.latex-support
      {
        name = "latex-support";
        publisher = "torn4dom4n";
        version = "4.0.0";
        sha256 = "1v1n8x8a13j8w1smmcr8vrblyxsr795zjb90cqs7shjl5q3l8ja7";
      }
      #twxs.cmake
      {
        name = "cmake";
        publisher = "twxs";
        version = "0.0.17";
        sha256 = "sha256-CFiva1AO/oHpszbpd7lLtDzbv1Yi55yQOQPP/kCTH4Y=";
      }
      # Java
      #vscjava.vscode-java-debug
      {
        name = "vscode-java-debug";
        publisher = "vscjava";
        version = "0.41.2022061304";
        sha256 = "10jcnqd8z9jxz958ymvb40fcfgvlz8f7vc67q1f2yz0l4h5prgn5";
      }
      #vscjava.vscode-java-dependency
      {
        name = "vscode-java-dependency";
        publisher = "vscjava";
        version = "0.20.2022062500";
        sha256 = "1cjm92pavmfvkls70aqv0xad0bi8qfxp9kpjxj8b3j8dprd2f4iq";
      }
      #vscjava.vscode-java-test
      {
        name = "vscode-java-test";
        publisher = "vscjava";
        version = "0.35.2022062402";
        sha256 = "1n3a0qpjwd43mmadwvma5lys52qwq4ad9lxl7rfbjgkfimj1c30j";
      }
      #vscjava.vscode-maven
      {
        name = "vscode-maven";
        publisher = "vscjava";
        version = "0.35.2022062203";
        sha256 = "0aa9nnnfh7v9wdwkpcahml0vh201ig11h2grl3xlc2adm0xqz8hb";
      }
    ] ++ lib.optionals (!useClangd && usePlatformIO) [
      # PlatformIO depends on ms-vscode.cpptools
      #platformio.platformio-ide
      {
        name = "platformio-ide";
        publisher = "platformio";
        version = "2.5.0";
        sha256 = "1vy97a35vbi0d5jb3f5v3zrbghs4pipia84rz83kkfljq7cjm7wh";
      }

    ]));

  vsCodeWithExtPkg = (pkgs.vscode-with-extensions.override {
    vscodeExtensions = vsExtensions;
  }) // {pname = "vscode";};
in {

  home.packages = with pkgs; lib.optionals useClangd [
    # Clang tools with clangd
    clang-tools
  ] ++ lib.optionals (!useClangd && usePlatformIO) [
    platformio
  ];

  programs.vscode = {
    enable = true;

#    package = pkgs.vscodium;
#    package = pkgs.vscode-fhs;
#    package = vsCodeWithExtPkg;
    package = pkgs.callPackage ./vscode-wayland-wrapper.nix { vscode = vsCodeWithExtPkg; };

#    extensions = vsExtensions;

    userSettings = {
      "editor.suggestSelection" = "first";
      # "editor.defaultFormatter" = "xaver.clang-format";
      "editor.formatOnPaste" = false;
      "editor.formatOnType" = true;
      # "editor.formatOnSave" = true;
      "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
      "vsintellicode.modelDownloadPath" = ".cache/vscode";
      "telemetry.enableTelemetry" = false;
      "telemetry.enableCrashReporter" = false;
      "telemetry.telemetryLevel" = "off";
      "C_Cpp.updateChannel" = "Insiders";
      "C_Cpp.clang_format_fallbackStyle" = "{BasedOnStyle: LLVM, UseTab: Never, IndentCaseLabels: true, NamespaceIndentation: All}";
      #"clangd.path" = "${pkgs.clang-tools}/bin/clangd";
      "todohighlight.keywords" = [
        "TODO"
        "FIXME"
      ];
      "todohighlight.include" = [
        "**/*.tex"
        "**/*.js"
        "**/*.jsx"
        "**/*.ts"
        "**/*.tsx"
        "**/*.html"
        "**/*.php"
        "**/*.css"
        "**/*.scss"
        "**/*.c"
        "**/*.v"
        "**/*.sv"
        "**/*.cpp"
        "**/*.tpp"
        "**/*.java"
        "**/*.h"
        "**/*.hpp"
      ];
      "files.eol" = "\n";
      "liveshare.featureSet" = "stable";
      "liveshare.anonymousGuestApproval" = "reject";
      "liveshare.guestApprovalRequired" = true;
      "liveshare.focusBehavior" = "prompt";
      "liveshare.autoShareServers" = false;
      "liveshare.codeLens" = false;
      "liveshare.diagnosticLogging" = true;
      "liveshare.diagnosticMode" = true;
      "java.semanticHighlighting.enabled" = true;
      "java.requirements.JDK11Warning" = false;
      "java.configuration.checkProjectSettingsExclusions" = false;
      "cSpell.language" = "en,en-US,de,de-de";
      "cSpell.enableFiletypes" = [
        "bat"
        "bibtex"
        "bsv"
        "cmake"
        "dockerfile"
        "lua"
        "makefile"
        "mlir"
        "nix"
        "powershell"
        "r"
        "raw"
        "ruby"
        "scad"
        "shellscript"
        "sql"
        "systemverilog"
        "tablegen"
        "tcl"
        "tex"
        "verilog"
        "xml"
      ];
      "workbench.editorAssociations" = {
          "*.ipynb" = "jupyter-notebook";
      };
      "workbench.colorTheme" = "Default Dark+";
      "cmake.configureOnOpen" = false;
      "notebook.cellToolbarLocation" = {
        "default" = "right";
        "jupyter-notebook" = "left";
      };
      "update.mode" = "none";
      "extensions.autoUpdate" = false;
      "extensions.ignoreRecommendations" = true;
      "platformio-ide.useBuiltinPIOCore" = false;
      "platformio-ide.activateOnlyOnPlatformIOProject" = true;
      "platformio-ide.disablePIOHomeStartup" = true;
      "mlir.onSettingsChanged" = "restart";
    };

  };

  # Create dummy file to ensure that the vscode intellisense cache folder exists
  home.file.".cache/vscode/.keep".text = "";

}
