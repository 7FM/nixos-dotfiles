{ config, pkgs, lib, ... }:

let
  runHeadless = config.custom.gui == "headless";
in {

  # Security
  services.usbguard.enable = true;
  # For headless:
  services.usbguard.package = if runHeadless then pkgs.usbguard-nox else pkgs.usbguard;

  # Allow unfree software :(
  nixpkgs.config.allowUnfree = true;

  # Enfore nixstore to be readonly
  nix.readOnlyStore = true;

  # User settings as i.e. the password may not be changed! Also no new users or groups can be added!
  users.mutableUsers = false;

}

