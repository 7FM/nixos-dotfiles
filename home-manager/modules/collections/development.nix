{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.collections.development.enable;
  withIntellij = false;
in {
  config = lib.mkIf enable (lib.mkMerge [(lib.mkIf withIntellij {
    home.packages = with pkgs; [
      jetbrains.idea-community
    ];

    # Intellij keymap settings
    xdg.configFile."JetBrains/IdeaIC2021.2/keymaps/VscodeLike.xml".source = ../../configs/JetBrains/IdeaIC2021.2/keymaps/VscodeLike.xml;
    xdg.configFile."JetBrains/IdeaIC2021.2/options/linux/keymap.xml".source = ../../configs/JetBrains/IdeaIC2021.2/options/linux/keymap.xml;

  }) (import ../submodule/vscode.nix { inherit config pkgs lib; })]);
}
