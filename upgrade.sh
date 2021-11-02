#!/bin/sh
set -ueo pipefail

# Update channels
echo "Update nix channels!"
nix-channel --update
sudo nix-channel --update

# Upgrade packages
echo "Upgrade packages!"
home-manager switch
sudo nixos-rebuild switch
