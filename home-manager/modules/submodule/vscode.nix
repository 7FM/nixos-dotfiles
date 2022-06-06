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
        version = "1.9.4";
        sha256 = "sha256-ZzmOECtWPBtgcxsjnd6lC+EWzJKTepB83GGRwnDUbjs=";
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
        version = "0.25.1";
        sha256 = "sha256-6drzZDC3yMh56Ku0Tx1U8IyaPmhzPj/Hpg1BPs3WAdA=";
      }
      #visualstudioexptteam.vscodeintellicode
      {
        name = "vscodeintellicode";
        publisher = "visualstudioexptteam";
        version = "1.2.17";
        sha256 = "sha256-4ixKPi3lFU3BIsmbWCrtJ5l3sUIOpzo4DTZvAZ1R6Ho=";
      }

      # Spelling
      #streetsidesoftware.code-spell-checker
      {
        name = "code-spell-checker";
        publisher = "streetsidesoftware";
        version = "2.1.6";
        sha256 = "sha256-k1v9ewVEj9rOYJ9qv9SH5zugEtbi3/WsyArfAdXrzJc=";
      }
      #streetsidesoftware.code-spell-checker-german
      {
        name = "code-spell-checker-german";
        publisher = "streetsidesoftware";
        version = "2.0.3";
        sha256 = "sha256-b5jAyOiFDKNeoz2JDXSYTOd3u3zIA7eNxacYLKWHJbA=";
      }

      # Language support
      #jakob-erzar.llvm-tablegen
      {
        name = "llvm-tablegen";
        publisher = "jakob-erzar";
        version = "0.0.2";
        sha256 = "sha256-W82Qtzl5KTyGcK8NWDWDlxfcAhcdgMHHh6mQsXnAzYk=";
      }
      # llvm-vs-code-extensions.vscode-mlir
      {
        name = "vscode-mlir";
        publisher = "llvm-vs-code-extensions";
        version = "0.0.3";
        sha256 = "sha256-Y8ZAY8jjQD2xh1QAxTlftcPdKFK3c+Ru3MsYTJgLupo=";
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
        version = "0.11.3";
        sha256 = "sha256-/0B1r04ZBpHx1o9a/uCotI+AeWvgIEJEl3ooGYwE/oo=";
      }
      #mshr-h.veriloghdl
      {
        name = "veriloghdl";
        publisher = "mshr-h";
        version = "1.5.3";
        sha256 = "sha256-4BXSG/YllhpXa0z7TqytKyqAKLJvSEsOLt1i6gA+WcE=";
      }
      #torn4dom4n.latex-support
      {
        name = "latex-support";
        publisher = "torn4dom4n";
        version = "3.10.0";
        sha256 = "sha256-kPhe102Lwcz4yelfxSj+n+Dob9fwoyZPYsUIupOrw8w=";
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
        version = "0.38.0";
        sha256 = "sha256-5QxKHa7fZH5MPkWrz5hCpP66VzICayxqE92jnPE7suQ=";
      }
      #vscjava.vscode-java-dependency
      {
        name = "vscode-java-dependency";
        publisher = "vscjava";
        version = "0.19.0";
        sha256 = "sha256-TOxDcqyjybilIt4+H3An5i+YcrjbOOLulMy+LDu296Q=";
      }
      #vscjava.vscode-java-test
      {
        name = "vscode-java-test";
        publisher = "vscjava";
        version = "0.34.0";
        sha256 = "sha256-7uscmiZNvwXZeDutsWmhkWe4IQ3VZx3Cna9xWM2wLhE=";
      }
      #vscjava.vscode-maven
      {
        name = "vscode-maven";
        publisher = "vscjava";
        version = "0.35.0";
        sha256 = "sha256-rJputnM6LtZ9+8H6Mjwh8OJSArSX2gSogtmLLoucffc=";
      }
    ] ++ lib.optionals (!useClangd && usePlatformIO) [
      # PlatformIO depends on ms-vscode.cpptools
      #platformio.platformio-ide
      {
        name = "platformio-ide";
        publisher = "platformio";
        version = "2.4.3";
        sha256 = "sha256-pPPukV0LZ/ZFp5Q+O7MhuCK5Px1FPy1ENzl21Ro7KFA=";
      }

    ]));

  vsCodeWithExtPkg = (pkgs.vscode-with-extensions.override {
    vscodeExtensions = vsExtensions;
  }) // {pname = "vscode";};
in {

  home.packages = with pkgs; lib.optionals useClangd [
    # Clang tools with clangd
    clang-tools
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
      "C_Cpp.clang_format_fallbackStyle" = "{BasedOnStyle: LLVM, UseTab: Never, IndentWidth: 4, ContinuationIndentWidth: 4, TabWidth: 4, ColumnLimit: 0, IndentCaseLabels: true, NamespaceIndentation: All}";
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
      "extensions.showRecommendationsOnlyOnDemand" = true;
      "extensions.ignoreRecommendations" = true;
      "platformio-ide.useBuiltinPIOCore" = false;
      "platformio-ide.activateOnlyOnPlatformIOProject" = true;
      "platformio-ide.disablePIOHomeStartup" = true;
    };

  };

  # Create dummy file to ensure that the vscode intellisense cache folder exists
  home.file.".cache/vscode/.keep".text = "";

}
