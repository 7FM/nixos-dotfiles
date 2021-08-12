{ config, pkgs, lib, ... }:

{

  # Nix settings
  nix = {
    # Replaces duplicate files
    autoOptimiseStore = true;
    # Garbage collector
    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Also trigger gc if we are low on storage space:
    # Free up to 1 GiB if we have less than 100 MiB left!
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';

  };

  # Save some storage space by not including docs
  documentation.enable = false;

}

