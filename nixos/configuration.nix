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
    #./devices/lenovo_laptop.nix

    ./modules/systemConfig.nix

    ./modules/cpu_amd.nix
    ./modules/cpu_intel.nix
    ./modules/cpu_generic.nix
    ./modules/gpu.nix
    ./modules/gpu_amd.nix
    ./modules/gpu_intel.nix
    ./modules/gpu_nvidia.nix
    ./modules/gpu_generic.nix

    ./modules/swapfile.nix

    # Internationalisation specifics
    ./modules/internationalization.nix

    # Shared settings
    ./modules/grub.nix
    ./modules/ssh.nix
    ./modules/security.nix

    # Features
    ./modules/optimize_storage_space.nix
    ./modules/powermanagement.nix
    ./modules/networking.nix
    ./modules/bluetooth.nix
    ./modules/virtualisation.nix

    ./modules/wayland.nix
    ./modules/home-manager_wayland.nix
    ./modules/x11.nix
  ];

  # UDP performance fixes
  boot.kernel.sysctl = {
#    "net.core.rmem_max" = 512 * 1024;
    "net.core.rmem_max" = 25 * 1024 * 1024;
#    "net.core.rmem_default" = 512 * 1024;
    "net.core.rmem_default" = 25 * 1024 * 1024;
  };

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
    openssh.authorizedKeys.keys = import ./secrets/userAuthorizedSSHKeys.nix;
    # Set password hash, generated with 'mkpasswd -m sha-512 -s':
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

