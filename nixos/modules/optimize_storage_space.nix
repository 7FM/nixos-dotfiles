{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
in {

  # Nix settings
  nix = {
    # Replaces duplicate files
    settings.auto-optimise-store = true;
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

  # journal settings
  services.journald.extraConfig = ''
    SystemMaxUse=50M
    RuntimeMaxUse=10M
  '';

}

