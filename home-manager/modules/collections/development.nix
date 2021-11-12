{ config, pkgs, lib, ... }:

let
in {
  imports = [
    ../vscode.nix
  ];

  home.packages = with pkgs; [
    # IDEs
    jetbrains.idea-community
  ];

}
