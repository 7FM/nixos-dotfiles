#!/usr/bin/env sh

# Quit on error
set -ueo pipefail

# update flake inputs
nix flake update
# update the vscode extensions
vscodeExtensionUpdater
# commit updates
git add flake.lock
git commit -m "update flake inputs"
git add home-manager/modules/submodule/vscode-extensions.nix
git commit -m "update vscode extensions"
