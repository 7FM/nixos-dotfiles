#!/usr/bin/env sh

#sudo rm -rf /etc/nixos
#sudo ln -s $(pwd)/nixos /etc/nixos

# Quit on error
set -ueo pipefail

# Add home manager channel 21.05
nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.05.tar.gz home-manager
# Or use unstable
#nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
# Then: On NixOs you have to log out and sign back in

#TODO is there a work around?
rehash

nix-shell '<home-manager>' -A install

rehash

rm -rf ~/.config/nixpkgs
ln -s $(pwd)/home-manager ~/.config/nixpkgs

home-manager switch
