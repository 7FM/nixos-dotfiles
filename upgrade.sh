#!/bin/sh
nix-channel --update
sudo nix-channel --update
home-manager switch
sudo nixos-rebuild switch
