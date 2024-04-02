{ config, pkgs, lib, ... }:

let
  useClangd = true;
  usePlatformIO = true;

  marketplaceExtensions = (import ./vscode-extensions.nix);

  vsExtensions = with pkgs.vscode-extensions; [
      # Nix language support
      bbenoist.nix
      # Nix env selector
      arrterian.nix-env-selector

      # PDF Viewer
      tomoki1207.pdf

      # Live share
      ms-vsliveshare.vsliveshare
      # Remote server
      ms-vscode-remote.remote-ssh
      # C++
      (if useClangd then llvm-vs-code-extensions.vscode-clangd else ms-vscode.cpptools)
      # LLDB support
      vadimcn.vscode-lldb

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
      # Languagetool integration
      valentjn.vscode-ltex
  ] ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace (
      marketplaceExtensions
    ++ lib.optionals (!useClangd && usePlatformIO) [
      # PlatformIO depends on ms-vscode.cpptools
      #platformio.platformio-ide
      {
        name = "platformio-ide";
        publisher = "platformio";
        version = "2.5.4";
        sha256 = "sha256-/vBdZ6Mu1KlF+glqp5CNt9WeK1ECqfaivCnK8TisChg=";
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

    package = vsCodeWithExtPkg;

    enableUpdateCheck = false;
    mutableExtensionsDir = false;
    enableExtensionUpdateCheck = false;

    userSettings = {
      "editor.suggestSelection" = "first";
      "editor.formatOnPaste" = false;
      "editor.formatOnType" = true;
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
        "**/*.nix"
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
      "todohighlight.exclude" = [
        "**/.direnv/**"
        "**/node_modules/**"
        "**/bower_components/**"
        "**/dist/**"
        "**/build/**"
        "**/.direnv/**"
        "**/.vscode/**"
        "**/.github/**"
        "**/_output/**"
        "**/*.min.*"
        "**/*.map"
        "**/.next/**"
      ];
      "files.eol" = "\n";
      "git.openRepositoryInParentFolders" = "always";
      "liveshare.featureSet" = "stable";
      "liveshare.anonymousGuestApproval" = "reject";
      "liveshare.guestApprovalRequired" = true;
      "liveshare.focusBehavior" = "prompt";
      "liveshare.autoShareServers" = false;
      "liveshare.codeLens" = false;
      "liveshare.diagnosticLogging" = true;
      "liveshare.diagnosticMode" = true;
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
      "notebook.cellToolbarLocation" = {
        "default" = "right";
        "jupyter-notebook" = "left";
      };
      "extensions.autoUpdate" = false;
      "extensions.ignoreRecommendations" = true;
      "platformio-ide.useBuiltinPIOCore" = false;
      "platformio-ide.activateOnlyOnPlatformIOProject" = true;
      "platformio-ide.disablePIOHomeStartup" = true;
      "mlir.onSettingsChanged" = "restart";
      "files.watcherExclude" = {
        "**/.bloop" = true;
        "**/.metals" = true;
        "**/.ammonite" = true;
      };
      "remote.SSH.lockfilesInTmp" = true;
    };

  };

  # Create dummy file to ensure that the vscode intellisense cache folder exists
  home.file.".cache/vscode/.keep".text = "";

}
