{ pkgs, fetchFromGitHub, ghc }:

let
  releaseVersion = "v0.0.8";
in pkgs.haskell.lib.buildStackProject {
  inherit ghc;

  pname = "sv2v";
  version = releaseVersion;

  buildInputs = [ ghc ];

  src = fetchFromGitHub {
    owner = "zachjs";
    repo = "sv2v";
    rev = releaseVersion;
#TODO CHANGE
    sha256 = "0w3z97dcqcz3bf7w6fja4smkafmx9kvhzb9px4k2nfmmyxh4yfma";
  };
}
