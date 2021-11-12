{ pkgs ? import <nixpkgs> {} }:

let
  verilatorVersion = "4.214";
  verilatorSha256 = "sha256:07pl5q79glyapw4gjssaass0c75757aji8j1pl487z2c3s304gs8";

in pkgs.mkShell {
  # nativeBuildInputs is usually what you want -- tools you need to run
  nativeBuildInputs = with pkgs; [
    gtkwave
    gnumake
    clang
    icestorm # ice40 tools
    trellis # ecp5 tools
    nextpnrWithGui
    (yosys.overrideAttrs (oldAttrs: {
      patches = [
        ./yosys.patch
      ] ++ (oldAttrs.patches or []);
    }))

    (pkgs.callPackage ./verilator.nix { inherit verilatorVersion verilatorSha256; })

    # packages to build a stack project (here sv2v)
    # 1. git clone https://github.com/zachjs/sv2v && cd sv2v
    # 2. stack --nix build
    # 3. stack --nix install
    stack
  ];
}
