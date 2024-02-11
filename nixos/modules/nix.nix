{ config, pkgs, lib, ... }:

{

  # Pin global nix registry to the same nixpkgs commit as the remaining system
  nix.registry = {
    nixpkgs.to = {
      type = "path";
      path = pkgs.path;
    };
  };

}

