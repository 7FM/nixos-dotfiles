{ config, pkgs, lib, ... }:

let
  runHeadless = config.custom.gui == "headless";
in {

  config = {
    # Security
    services.usbguard.enable = true;

    # TODO change back to "block" once a policy is inplace!
    services.usbguard.implictPolicyTarget = "allow";

    # For headless:
    services.usbguard.package = if runHeadless then pkgs.usbguard-nox else pkgs.usbguard;

    # Allow unfree software :(
    nixpkgs.config.allowUnfree = true;

    # Enfore nixstore to be readonly
    nix.readOnlyStore = true;

    # User settings as i.e. the password may not be changed! Also no new users or groups can be added!
    users.mutableUsers = false;
    # Disable root login
    users.users.root.hashedPassword = "!";
    # Emergency mode requires root -> not usable anyway
    systemd.enableEmergencyMode = false;

    warnings = if (config.services.usbguard.implictPolicyTarget != "block") then [
      ''
        The fallback policy of usbguard should be set to block! Else no additional security is gained!
        HOWEVER, ensure that usbguard is setup with a policy before setting the fallback to block,
        else there might be no way to interact with the system!
      ''
    ] else [ ];

  };

}

