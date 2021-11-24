{
  description = "FPGA dev tools, focused on ICE40";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = let
          verilatorVersion = "4.214";
          verilatorSha256 = "sha256:07pl5q79glyapw4gjssaass0c75757aji8j1pl487z2c3s304gs8";
        in with pkgs; [
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
        buildInputs = [ ];
      };
    });
}