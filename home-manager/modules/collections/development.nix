{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.collections.development.enable;
in {
  config = lib.mkIf enable {
    imports = [
      ../vscode.nix
    ];

    home.packages = with pkgs; [
      # IDEs
      jetbrains.idea-community
    ];
  };
}
