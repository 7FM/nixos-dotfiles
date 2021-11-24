{
  description = "HiWi env flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = let
        myPyPackages = python-packages: with python-packages; [
         psutil
        ];

        myPythonWithPackages = pkgs.python3.withPackages myPyPackages;

      in pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          cmake
          ninja
          clang

          # Python env for the utility scripts
          myPythonWithPackages
        ];
        buildInputs = [ ];
      };
    });}
