# Source: https://github.com/malob/nixpkgs/blob/master/nixpkgs.nix
{
  system ? builtins.currentSystem,
  config ? {},
  overlays ? [],
  ...
}@args:

import (import (
  let
    lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  in fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  }) {
    src =  ./.;
  }
).defaultNix.inputs.nixpkgs args
