#!/usr/bin/env sh

# Quit on error
set -ueo pipefail

setup_sys() {
  sudo rm -rf /etc/nixos
  sudo ln -s $(pwd) /etc/nixos
}

upgrade() {
  echo "Update flake inputs!"
  nix flake update
  echo "Upgrade packages!"
  sudo nixos-rebuild switch
}

if [ $# -ne 1 ]; then
  echo "Usage: ./build.sh <task>"
  echo "Available tasks: setup_sys, upgrade"
  exit 1
fi

# show output of all commands
set -x

case $1 in
  "setup_sys")
    setup_sys;;
  "upgrade")
    upgrade;;
  *)
    echo "Invalid option!";;
esac
