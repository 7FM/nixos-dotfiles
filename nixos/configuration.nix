forceNoSecrets: deviceName:
{ config, pkgs, lib, ... }:

# Window system settings:
let
  runHeadless = config.custom.gui == "headless";

  tools = import ./common/lib { inherit config pkgs lib; };
in {

  custom.useDummySecrets = if forceNoSecrets then lib.mkForce true else lib.mkDefault true;

  imports = [
    (import ./common/devices.nix false deviceName)
    ./modules/systemConfig.nix
  ];

  # UDP performance fixes
  boot.kernel.sysctl = {
#    "net.core.rmem_max" = 512 * 1024;
    "net.core.rmem_max" = 25 * 1024 * 1024;
#    "net.core.rmem_default" = 512 * 1024;
    "net.core.rmem_default" = 25 * 1024 * 1024;
  };

  # add flakes feature
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  # Add convenient wrapper
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nixFlakes" ''
      exec ${pkgs.nixFlakes}/bin/nix --experimental-features "nix-command flakes" "$@"
    '')
  ];

  # Additional hardware settings
  #hardware.usbWwan.enable = true;

  services.xserver.displayManager.autoLogin.enable = false;

  # Enable CUPS to print documents.
  services.printing = {
    enable = !runHeadless;
    drivers = with pkgs; [
      cnijfilter2 # Canon Pixma Drivers
    ];
  };
  # Scanner Support
  hardware.sane.enable = !runHeadless;

  # Enable sound.
  sound.enable = !runHeadless;
  hardware.pulseaudio = {
    enable = !runHeadless;
    support32Bit = !runHeadless;
  };

  # Use zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  #  promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  environment.shells = [ pkgs.zsh ];  
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  services.xserver.displayManager.autoLogin.user = "tm";

  users.users.tm = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ 
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager" # Allow changing the network settings
      "video" # For sound settings
      "scanner" # For scanners
      "lp" # For scanners
    ];
    openssh.authorizedKeys.keys = tools.getSecret ./. "userAuthorizedSSHKeys.nix";
    # Set password hash, generated with 'mkpasswd -m sha-512 -s':
    hashedPassword = tools.getSecret ./. "password.nix";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}

