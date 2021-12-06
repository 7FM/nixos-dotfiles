{ config, pkgs, lib, ... }:

let
  useClangd = true;

  vsExtensions = with pkgs.vscode-extensions; [
      # Nix language support
      bbenoist.nix
      # Nix env selector
      arrterian.nix-env-selector

      # Live share
      ms-vsliveshare.vsliveshare
      # C++
      (if useClangd then llvm-vs-code-extensions.vscode-clangd else ms-vscode.cpptools)

      # Python
      ms-python.python
      ms-python.vscode-pylance
      ms-toolsai.jupyter
      # Java
      redhat.java
      # Scala
      scala-lang.scala
    ] ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #ms-vscode.cmake-tools
      {
        name = "cmake-tools";
        publisher = "ms-vscode";
        version = "1.7.3";
        sha256 = "0jisjyk5n5y59f1lbpbg8kmjdpnp1q2bmhzbc1skq7fa8hj54hp9";
      }
      #ms-vscode.hexeditor
      {
        name = "hexeditor";
        publisher = "ms-vscode";
        version = "1.8.2";
        sha256 = "106k40gfcgjqcflnmdrr777wn0sb5m6fv1smsh692znd9bndf02k";
      }
      #ms-vscode.notepadplusplus-keybindings
      {
        name = "notepadplusplus-keybindings";
        publisher = "ms-vscode";
        version = "1.0.7";
        sha256 = "148mz6jvlq7jycsyf8fxczbv90bmnj1gzb7p9mvfdprb38kf6bw8";
      }
      #wayou.vscode-todo-highlight
      {
        name = "vscode-todo-highlight";
        publisher = "wayou";
        version = "1.0.4";
        sha256 = "0s925rb668spv602x6g7sld2cs5ayiq7273963v9prvgsr0drlrr";
      }
      #webfreak.debug
      {
        name = "debug";
        publisher = "webfreak";
        version = "0.25.1";
        sha256 = "1l01sv6kwh8dlv3kygkkd0z9m37hahflzd5bx1wwij5p61jg7np9";
      }
      #visualstudioexptteam.vscodeintellicode
      {
        name = "vscodeintellicode";
        publisher = "visualstudioexptteam";
        version = "1.2.14";
        sha256 = "1j72v6grwasqk34m1jy3d6w3fgrw0dnsv7v17wca8baxrvgqsm6g";
      }

      # Spelling
      #streetsidesoftware.code-spell-checker
      {
        name = "code-spell-checker";
        publisher = "streetsidesoftware";
        version = "1.10.2";
        sha256 = "1ll046rf5dyc7294nbxqk5ya56g2bzqnmxyciqpz2w5x7j75rjib";
      }
      #streetsidesoftware.code-spell-checker-german
      {
        name = "code-spell-checker-german";
        publisher = "streetsidesoftware";
        version = "0.1.9";
        sha256 = "1pphp2nyk4acmp1jmawsiwp3ijniija8fz0fd5icdsndmp03hc5f";
      }

      # PlatformIO
      #platformio.platformio-ide
      #{
      #  name = "platformio-ide";
      #  publisher = "platformio";
      #  version = "2.3.2";
      #  sha256 = "0z7cd6ya0mr10lwdbh47j8if3spwzz2scr8v06jfs0q4h8ybzgf4";
      #}

      # Language support
      #jakob-erzar.llvm-tablegen
      {
        name = "llvm-tablegen";
        publisher = "jakob-erzar";
        version = "0.0.2";
        sha256 = "12fdq1wv3459hz3w300x2w1dq5wphcsmh3dgf233qabr76vr1kav";
      }
      # llvm-vs-code-extensions.vscode-mlir
      {
        name = "vscode-mlir";
        publisher = "llvm-vs-code-extensions";
        version = "0.0.2";
        sha256 = "1sf9l4qhki2pnmbdc1py7qigpk36h1hn8ickiizhi0zznprjbaqr";
      }
      #antyos.openscad
      {
        name = "openscad";
        publisher = "antyos";
        version = "1.1.1";
        sha256 = "1adcw9jj3npk3l6lnlfgji2l529c4s5xp9jl748r9naiy3w3dpjv";
      }
      #bkromhout.vscode-tcl
      {
        name = "vscode-tcl";
        publisher = "bkromhout";
        version = "0.2.0";
        sha256 = "1w38rrfii5cy9606pp6prif4jygwdwql6c2ik6rj26ym8wiffagl";
      }
      #eirikpre.systemverilog
      {
        name = "systemverilog";
        publisher = "eirikpre";
        version = "0.11.3";
        sha256 = "12py0j61ja3sjx244870ddwq13xlm3hgwnlgsvqr21hr9sppah7z";
      }
      #mshr-h.veriloghdl
      {
        name = "veriloghdl";
        publisher = "mshr-h";
        version = "1.5.1";
        sha256 = "16zpnzbp8sxv7xhkqpf2qgvrvr9a692yg0fdkmk86hq1lqa8cm7v";
      }
      #torn4dom4n.latex-support
      {
        name = "latex-support";
        publisher = "torn4dom4n";
        version = "3.9.0";
        sha256 = "1264yy8p6zm0qsip02p2sqan120xv0kbk4v92blblmz97vgw0my4";
      }
      #twxs.cmake
      {
        name = "cmake";
        publisher = "twxs";
        version = "0.0.17";
        sha256 = "11hzjd0gxkq37689rrr2aszxng5l9fwpgs9nnglq3zhfa1msyn08";
      }
      # Java
      #vscjava.vscode-java-debug
      {
        name = "vscode-java-debug";
        publisher = "vscjava";
        version = "0.35.0";
        sha256 = "01sskdm7fizzh6d8bzgdmj9pmrshvh58ks0l6qyf0gr2ifnhli57";
      }
      #vscjava.vscode-java-dependency
      {
        name = "vscode-java-dependency";
        publisher = "vscjava";
        version = "0.18.6";
        sha256 = "1yycwah5pwdifmkgxk39x3z5zkg29m525n0sfwbm42y7fx3anby0";
      }
      #vscjava.vscode-java-test
      {
        name = "vscode-java-test";
        publisher = "vscjava";
        version = "0.31.1";
        sha256 = "0nfb9pawsqmcp769qwaslrryy75w76s02qvlyxnn9g1c9xh92p2s";
      }
      #vscjava.vscode-maven
      {
        name = "vscode-maven";
        publisher = "vscjava";
        version = "0.32.2";
        sha256 = "0hn37li6wv5w0m92svr1bmmspwrwcn7k7bm59a58kfgs5j8sccax";
      }
    ]);

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
      "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
      "vsintellicode.modelDownloadPath" = ".cache/vscode";
      "telemetry.enableTelemetry" = false;
      "telemetry.enableCrashReporter" = false;
      "telemetry.telemetryLevel" = "off";
      "C_Cpp.updateChannel" = "Insiders";
      "editor.formatOnPaste" = false;
      "editor.formatOnType" = true;
      "C_Cpp.clang_format_fallbackStyle" = "{BasedOnStyle: LLVM, UseTab: Never, IndentWidth: 4, TabWidth: 4, ColumnLimit: 0, IndentCaseLabels: true, NamespaceIndentation: All}";
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
      "cSpell.language" = "en,en-US";
      "cSpell.enableFiletypes" = [
        "bat"
        "bibtex"
        "bsv"
        "cmake"
        "dockerfile"
        "makefile"
        "mlir"
        "nix"
        "powershell"
        "r"
        "ruby"
        "scad"
        "shellscript"
        "sql"
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
    };

  };

  # Create dummy file to ensure that the vscode intellisense cache folder exists
  home.file.".cache/vscode/.keep".text = "";

}
