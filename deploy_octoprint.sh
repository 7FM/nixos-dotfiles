#!/bin/sh
nixos-rebuild switch \
  --flake .#nixos-octoprint \
  --target-host octopi --elevate=sudo --ask-elevate-password
