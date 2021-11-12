#!/usr/bin/env sh

# Quit on error
set -ueo pipefail

prepare_hm() {
  mkdir -p $HOME/.config
  rm -rf $HOME/.config/nixpkgs
  ln -s $(pwd)/home-manager $HOME/.config/nixpkgs
}

setup_hm() {
  # Add home manager channel 21.05
  nix-channel --add https://github.com/nix-community/home-manager/archive/release-21.05.tar.gz home-manager
  # Or use unstable
  #nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
  nix-shell '<home-manager>' -A install
  rehash
}

install_hm() {
  prepare_hm
  setup_hm

  home-manager switch
}

upgrade_hm() {
  echo "Update nix channels!"
  nix-channel --update
  echo "Upgrade packages!"
  home-manager switch
}

setup_sys() {
  sudo rm -rf /etc/nixos
  sudo ln -s $(pwd)/nixos /etc/nixos
}

upgrade_sys() {
  echo "Update nix channels!"
  sudo nix-channel --update
  echo "Upgrade packages!"
  sudo nixos-rebuild switch
}

upgrade() {
  upgrade_sys
  upgrade_hm
}

switch_to_unstable() {
  # home-manager
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  # system
  sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos

  upgrade
}

if [ $# -ne 1 ]; then
  echo "Usage: ./build.sh <task>"
  echo "Available tasks: switch_unstable, setup_sys, upgrade_sys, upgrade_hm, upgrade, install_hm"
  exit 1
fi

# show output of all commands
set -x

case $1 in
  "switch_unstable")
    switch_to_unstable;;
  "setup_sys")
    setup_sys;;
  "upgrade_sys")
    upgrade_sys;;
  "upgrade_hm")
    upgrade_hm;;
  "upgrade")
    upgrade;;
  "install_hm")
    install_hm;;
  *)
    echo "Invalid option!";;
esac
