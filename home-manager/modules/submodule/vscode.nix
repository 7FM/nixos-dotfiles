{ config, pkgs, lib, ... }:

let
  useClangd = false;
  usePlatformIO = true;

  marketplaceExtensions = [
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
  ] ++ (import ./vscode-extensions.nix);

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
  ] ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace (
      marketplaceExtensions
    ++ lib.optionals (!useClangd && usePlatformIO) [
      # PlatformIO depends on ms-vscode.cpptools
      #platformio.platformio-ide
      {
        name = "platformio-ide";
        publisher = "platformio";
        version = "2.5.2";
        sha256 = "sha256-RWO47AVEarIpakkHGFXjtI0UOzCRBFFgPH6bAfOfXbk=";
      }
  ]));

  vsCodeWithExtPkg = (pkgs.vscode-with-extensions.override {
    vscodeExtensions = vsExtensions;
  }) // {pname = "vscode";};

  extractExtensionInfo = extensions: builtins.concatStringsSep "\\n" (map (e: 
    builtins.concatStringsSep "." [(builtins.getAttr "publisher" e) (builtins.getAttr "name" e)]
  ) extensions);

  extensionUpdaterHelperScript = (pkgs.writeScript "extensionUpdaterHelperScript" (import ./vscode-extension-updater.nix (extractExtensionInfo marketplaceExtensions)));
  vscodeExtensionUpdater = (pkgs.writeShellScriptBin "vscodeExtensionUpdater" ''
    ${extensionUpdaterHelperScript} > /home/${config.home.username}/nixos-dotfiles/home-manager/modules/submodule/vscode-extensions.nix
  '');

in {

  home.packages = with pkgs; [
    vscodeExtensionUpdater
  ] ++ lib.optionals useClangd [
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
      "C_Cpp.clang_format_fallbackStyle" = "{BasedOnStyle: LLVM, UseTab: Never, IndentCaseLabels: true, NamespaceIndentation: All, AlwaysBreakTemplateDeclarations: Yes}";
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
