{ pkgs ? import <nixpkgs> {} }:

let
  verilatorVersion = "4.212";
  verilatorSha256 = "sha256:1sxijsy0yr7z9whr7db1afy374dxbylx4xfryw9brh002gbj8qj0";

in pkgs.mkShell {
  # nativeBuildInputs is usually what you want -- tools you need to run
  nativeBuildInputs = with pkgs; [
    gtkwave
    gnumake
    clang
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
