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

    # Custom packed sv2v
    #(pkgs.callPackage ./sv2v.nix { })
  ];
}
