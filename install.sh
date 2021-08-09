#!/usr/bin/env sh

# Quit on error
set -e

# Add home manager channel 21.05
nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.05.tar.gz home-manager
nix-channel --update
# Then: On NixOs you have to log out and sign back in

#TODO is there a work around?

nix-shell '<home-manager>' -A install

rm -rf ~/.config/nixpkgs
ln -s $(pwd)/home-manager ~/.config/nixpkgs

home-manager switch
