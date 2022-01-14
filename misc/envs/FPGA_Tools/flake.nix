{
  description = "FPGA dev tools, focused on ICE40";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = let
          verilatorVersion = "4.216";
          verilatorSha256 = "sha256-F2QPZPZp/A0k4YSMOHrtUjmrO7/Gd4GWXbwdMFxuFUo=";

          #libsigrokVersion = "0.5.2";
          #libsigrokSha256 = "sha256-TTQfkLYiDT6MslHaz3JsQRZShWEiSPLFLRXfRZChzjw=";
          libsigrokVersion = "f6c42ac0a33d03ba0ea6509baede92c540687f84";
          libsigrokSha256 = "sha256-UVzAV8Z53Eb9klMsitETmD17cNnQJgcJ2l3CH2PgSRg=";

          #libsigrokdecodeVersion = "0.5.3";
          #libsigrokdecodeSha256 = "1h1zi1kpsgf6j2z8j8hjpv1q7n49i3fhqjn8i178rka3cym18265";
          libsigrokdecodeVersion = "da253ef59221744f7258720861638bd1ae2e335f";
          libsigrokdecodeSha256 = "sha256-0dUpqOSkNd7YxERMiCSOwFbLirvgVc2bFeEZPY9RUIA=";

          #pulseviewVersion = "0.4.2";
          #pulseviewSha256 = "sha256-8EL3ej4bNb8wZmMw427Dj6uNJIw2k8N7fjXUAcO/q8s=";
          pulseviewVersion = "fe94bf8255145410d1673880932d59573c829b0e";
          pulseviewSha256 = "sha256-XQp/g0QYHgY5SbXo8+OCCdoOGeUu+BSXioJExMh5baM=";
        in with pkgs; [
          gtkwave
          gnumake
          #clang
          icestorm # ice40 tools
          trellis # ecp5 tools
          nextpnrWithGui
          (pkgs.libsForQt514.callPackage ./pulseview.nix { 
            inherit libsigrokVersion libsigrokSha256;
            inherit libsigrokdecodeVersion libsigrokdecodeSha256;
            version = pulseviewVersion; sha256 = pulseviewSha256;
          })

          (yosys.overrideAttrs (oldAttrs: {
            patches = [
              ./yosys.patch
            ] ++ (oldAttrs.patches or []);
          }))

          (pkgs.callPackage ./verilator.nix { inherit verilatorVersion verilatorSha256; })
          zlib # Needed for verilator fst exports

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
