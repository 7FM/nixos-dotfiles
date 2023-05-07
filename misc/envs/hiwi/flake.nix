{
  description = "HiWi env flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = let
        myPyPackages = python-packages: with python-packages; [
         cocotb
         psutil
         numpy
         pyyaml
         pytest
         autopep8 # autoformatter
        ];

        myPythonWithPackages = pkgs.python3.withPackages myPyPackages;

      in pkgs.mkShellNoCC {
        nativeBuildInputs = with pkgs; [
          gcc
          cmake
          ninja
          or-tools
          clang_12
          clang-tools # for clangd
          gdb
          verilog
          (verilator.overrideAttrs (oldAttrs: rec { 
            version = "4.106";
            src = fetchFromGitHub {
              owner = "verilator";
              repo = "verilator";
              rev = "v" + version;
              sha256 = "sha256-XoAz5fbX1olOt31UbBuQsyG+sdKUlHaKi+VeLv8c4Xk=";
            };

            patches = [
              (fetchpatch {
                url = "https://github.com/verilator/verilator/pull/2747.patch";
                sha256 = "sha256-QdflAa8B7JR6WHCuohdX4KgB/lSwtDojJvRn7j8RVQo=";
              })
            ];

            doCheck = false;
          }))
          yosys
          gtkwave
          zlib # Needed for verilator fst exports

          jq # Needed for open dot helper script

          # Python env for the utility scripts & cocotb
          myPythonWithPackages
        ];
        buildInputs = [ ];
      };
    });}
