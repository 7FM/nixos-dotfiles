{ config, pkgs, lib, ... }:

# Window system settings:
let
  additionalPackages = with pkgs; [
    #linuxPackages_hardened.broadcom_sta
    #linuxPackages.rtl8812au
  ];

  runHeadless = config.custom.gui == "headless";
in {

  imports = [
    # Hardware specifics
    #./devices/virtualbox.nix
    ./devices/desktop.nix

    ./common/systemConfig.nix

    ./common/cpu_amd.nix
    ./common/cpu_intel.nix
    ./common/cpu_generic.nix
    ./common/gpu.nix
    ./common/gpu_amd.nix
    ./common/gpu_intel.nix
    ./common/gpu_nvidia.nix
    ./common/gpu_generic.nix

    ./common/swapfile.nix

    # Internationalisation specifics
    ./common/internationalization.nix

    # Shared settings
    ./common/grub.nix
    ./common/ssh.nix
    ./common/security.nix

    # Features
    ./common/optimize_storage_space.nix
    ./common/powermanagement.nix
    ./common/networking.nix

    ./common/wayland.nix
    ./common/x11.nix
  ];

  # Additional hardware settings
  #hardware.usbWwan.enable = true;

  services.xserver.displayManager.autoLogin.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = !runHeadless;

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
    ];
    openssh.authorizedKeys.keys = import ./secrets/userAuthorizedSSHKeys.nix;
    # Set password hash, generated with 'mkpasswd -m sha-512 <password>':
    hashedPassword = import ./secrets/password.nix;
  };

  environment.systemPackages = with pkgs; [
  ] ++ additionalPackages;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}

