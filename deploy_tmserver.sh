#!/bin/sh
nixos-rebuild switch \
  --flake .#nixos-tmserver-x86 \
  --target-host tmserver_ssh --elevate=sudo --ask-elevate-password
