{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    # Compiler & related
    python3Minimal
    gcc
    clang
    cmake
    gdb
    jdk
    # IDEs
    jetbrains.idea-community
    gtkwave
  ];

  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
      # Live share
      ms-vsliveshare.vsliveshare

      ms-vscode.cpptools
    ] ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #ms-vscode.cmake-tools
      {
        name = "cmake-tools";
        publisher = "ms-vscode";
        version = "1.7.3";
        sha256 = "";
      }
      #ms-vscode.hexeditor
      {
        name = "hexeditor";
        publisher = "ms-vscode";
        version = "1.8.2";
        sha256 = "";
      }
      #ms-vscode.notepadplusplus-keybindings
      {
        name = "notepadplusplus-keybindings";
        publisher = "ms-vscode";
        version = "1.0.7";
        sha256 = "";
      }
      #wayou.vscode-todo-highlight
      {
        name = "vscode-todo-highlight";
        publisher = "wayou";
        version = "1.0.4";
        sha256 = "";
      }
      #webfreak.debug
      {
        name = "debug";
        publisher = "webfreak";
        version = "0.25.1";
        sha256 = "";
      }
      #visualstudioexptteam.vscodeintellicode
      {
        name = "vscodeintellicode";
        publisher = "visualstudioexptteam";
        version = "1.2.14";
        sha256 = "";
      }

      # Spelling
      #streetsidesoftware.code-spell-checker
      {
        name = "code-spell-checker";
        publisher = "streetsidesoftware";
        version = "1.10.2";
        sha256 = "";
      }
      #streetsidesoftware.code-spell-checker-german
      {
        name = "code-spell-checker-german";
        publisher = "streetsidesoftware";
        version = "0.1.9";
        sha256 = "";
      }

      # PlatformIO
      #platformio.platformio-ide
      {
        name = "platformio-ide";
        publisher = "platformio";
        version = "2.3.2";
        sha256 = "";
      }

      # Language support
      #antyos.openscad
      {
        name = "openscad";
        publisher = "antyos";
        version = "1.1.1";
        sha256 = "";
      }
      #bkromhout.vscode-tcl
      {
        name = "vscode-tcl";
        publisher = "bkromhout";
        version = "0.2.0";
        sha256 = "";
      }
      #eirikpre.systemverilog
      {
        name = "systemverilog";
        publisher = "eirikpre";
        version = "0.11.3";
        sha256 = "";
      }
      #mshr-h.veriloghdl
      {
        name = "veriloghdl";
        publisher = "mshr-h";
        version = "1.5.0";
        sha256 = "";
      }
      #torn4dom4n.latex-support
      {
        name = "latex-support";
        publisher = "torn4dom4n";
        version = "3.9.0";
        sha256 = "";
      }
      #twxs.cmake
      {
        name = "cmake";
        publisher = "twxs";
        version = "0.0.17";
        sha256 = "";
      }
      # Java
      #vscjava.vscode-java-debug
      {
        name = "vscode-java-debug";
        publisher = "vscjava";
        version = "0.35.0";
        sha256 = "";
      }
      #vscjava.vscode-java-dependency
      {
        name = "vscode-java-dependency";
        publisher = "vscjava";
        version = "0.18.6";
        sha256 = "";
      }
      #vscjava.vscode-java-test
      {
        name = "vscode-java-test";
        publisher = "vscjava";
        version = "0.31.1";
        sha256 = "";
      }
      #vscjava.vscode-maven
      {
        name = "vscode-maven";
        publisher = "vscjava";
        version = "0.32.2";
        sha256 = "";
      }
    ]) ++ (with pkgs.vscode-extensions; [

      # Python
      ms-python.python
      ms-python.vscode-pylance
      ms-toolsai.jupyter
      # Java
      redhat.java
    ]);

    userSettings = {
      "editor.suggestSelection" = "first";
      "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
      "telemetry.enableTelemetry" = false;
      "telemetry.enableCrashReporter" = false;
      "C_Cpp.updateChannel" = "Insiders";
      "editor.formatOnPaste" = false;
      "editor.formatOnType" = true;
      "C_Cpp.clang_format_fallbackStyle" = "{BasedOnStyle: LLVM, UseTab: Never, IndentWidth: 4, TabWidth: 4, ColumnLimit: 0, IndentCaseLabels: true, NamespaceIndentation: All}";
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
      "liveshare.accountProvider" = "";
      "liveshare.account" = "";
      "liveshare.focusBehavior" = "prompt";
      "liveshare.autoShareServers" = false;
      "liveshare.codeLens" = false;
      "java.semanticHighlighting.enabled" = true;
      "java.requirements.JDK11Warning" = false;
      "java.configuration.checkProjectSettingsExclusions" = false;
      "cSpell.language" = "en,en-US";
      "workbench.editorAssociations" = {
          "*.ipynb" = "jupyter-notebook";
      };
      "cmake.configureOnOpen" = false;
      "notebook.cellToolbarLocation" = {
        "default" = "right";
        "jupyter-notebook" = "left";
      };
    };

  };
}
