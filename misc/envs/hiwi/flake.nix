{
  description = "HiWi env flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in {
      devShell = with pkgs; let
        myPython = let
          packageOverrides = self: super: {
           cocotb = super.cocotb.overridePythonAttrs (oldAttrs: rec {
             version = "1.8.0";
             src = fetchFromGitHub {
               owner = "cocotb";
               repo = "cocotb";
               rev = "refs/tags/v${version}";
               hash = "sha256-k3VizQ9iyDawfDCeE3Zup/KkyD54tFBLdQvRKsbKDLY=";
             };
             doCheck = false;
           });
          };
        in pkgs.python3.override {inherit packageOverrides; };

        myPyPackages = python-packages: with python-packages; [
          find-libpython
          cocotb
          psutil
          numpy
          pyyaml
          pytest
          autopep8 # autoformatter
        ];

        myPythonWithPackages = myPython.withPackages myPyPackages;

        my_gurobi = (gurobi.overrideAttrs (oldAttrs: rec {
          version = "10.0.2";
          sourceRoot = "gurobi${builtins.replaceStrings ["."] [""] version}/linux64";
          src = fetchurl {
            url = "https://packages.gurobi.com/${lib.versions.majorMinor version}/gurobi${version}_linux64.tar.gz";
            sha256 = "sha256-A9osYUlPX4AJgnC6RZ11Z9uLC/BYhN29injlsosAjck=";
          };
        }));

      # TODO use stdEnv?
      in mkShellNoCC {
        shellHook = ''
          export GUROBI_HOME="${my_gurobi}/"
          export GRB_LICENSE_FILE="/home/tm/hiwi/longnail/gurobi.lic"
        '';

        nativeBuildInputs = [
          gcc
          cmake
          ninja
          clang_12
          clang-tools # for clangd
          gdb
          verilog
          verilator
          yosys
          gtkwave
          zlib # Needed for verilator fst exports

          jq # Needed for open dot helper script

          # commercial ILP solver
          my_gurobi

          graphviz # convert dot graphs to an image

          # Python env for the utility scripts & cocotb
          myPythonWithPackages
        ];
      };
    });}
