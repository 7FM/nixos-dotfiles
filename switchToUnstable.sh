#!/bin/sh
set -ueo pipefail

# home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
# system
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos

./upgrade.sh
