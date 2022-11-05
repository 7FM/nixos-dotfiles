#!/usr/bin/env sh

# Quit on error
set -ueo pipefail

# update flake inputs
nix flake update
# update the vscode extensions
vscodeExtensionUpdater
