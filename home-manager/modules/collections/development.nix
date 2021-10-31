{ config, pkgs, lib, ... }:

let
  # Create an overlay to fix collisions between gcc & clang for bin/c{c,pp,++}
  # For now default to gcc, we might want to change this in the future!
  myClang = pkgs.clang.overrideAttrs (oldAttrs: {
#    postInstall = (oldAttrs.postInstall or "") + ''
#      rm $out/bin/cpp
#      rm $out/bin/cc
#      rm $out/bin/c++
#    '';
    installPhase = (oldAttrs.installPhase or "") + ''
      rm $out/bin/cpp
      rm $out/bin/cc
      rm $out/bin/c++
    '';
  });

in {
  imports = [
    ../vscode.nix
  ];

  home.packages = with pkgs; [
    # Compiler & related
    #python3Minimal
    gcc # For now use gcc as default for the cpp binary
#    clang
    myClang # use the patched clang version
    cmake
    gnumake
    gdb
    # IDEs
    jetbrains.idea-community
    gtkwave
  ];

  programs.java.enable = true;
}
