#!/usr/bin/env sh
#ln -s $(pwd)/home.nix ~/.config/nixpkgs/home.nix
rm -rf ~/.config/nixpkgs
ln -s $(pwd) ~/.config/nixpkgs
