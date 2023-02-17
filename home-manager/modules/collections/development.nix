{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.collections.development.enable;
in {
  config = lib.mkIf enable (lib.mkMerge [{
    # imports = [
    #   ../vscode.nix
    # ];

    home.packages = with pkgs; [
      # IDEs
      jetbrains.idea-community
    ];

    # Intellij keymap settings
    xdg.configFile."JetBrains/IdeaIC2021.2/keymaps/VscodeLike.xml".source = ../../configs/JetBrains/IdeaIC2021.2/keymaps/VscodeLike.xml;
    xdg.configFile."JetBrains/IdeaIC2021.2/options/linux/keymap.xml".source = ../../configs/JetBrains/IdeaIC2021.2/options/linux/keymap.xml;

  } (import ../submodule/vscode.nix { inherit config pkgs lib; })]);
}
