forceNoSecrets: deviceName: userName:
{ config, pkgs, lib, ... }:

# Window system settings:
let
  runHeadless = config.custom.gui == "headless";
  myTools = pkgs.myTools { inherit config pkgs lib; };
in {

  custom.useDummySecrets = if forceNoSecrets then lib.mkForce true else lib.mkDefault true;

  imports = [
    (import ../common/devices.nix false deviceName)
    (import ./modules/systemConfig.nix deviceName userName)
  ];

  ## Enable BBR module
  boot.kernelModules = [ "tcp_bbr" ];

  boot.kernel.sysctl = {
    # Performance settings
#    "net.core.rmem_max" = 512 * 1024;
    "net.core.rmem_max" = 25 * 1024 * 1024;
#    "net.core.rmem_default" = 512 * 1024;
    "net.core.rmem_default" = 25 * 1024 * 1024;
    # Source: https://mdleom.com/blog/2020/03/04/caddy-nixos-part-2/
    # TCP Fast Open (TFO)
    "net.ipv4.tcp_fastopen" = 3;
    ## Bufferbloat mitigations
    # Requires >= 4.9 & kernel module
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Requires >= 4.19
    "net.core.default_qdisc" = "cake";

    # Some hardening settings
    # Disable magic SysRq key
    "kernel.sysrq" = 0;
    # Ignore ICMP broadcasts to avoid participating in Smurf attacks
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Ignore bad ICMP errors
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Reverse-path filter for spoof protection
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    # SYN flood protection
    "net.ipv4.tcp_syncookies" = 1;
    # Do not accept ICMP redirects (prevent MITM attacks)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # Do not send ICMP redirects (we are not a router)
    "net.ipv4.conf.all.send_redirects" = 0;
    # Do not accept IP source route packets (we are not a router)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    # Protect against tcp time-wait assassination hazards
    "net.ipv4.tcp_rfc1337" = 1;
  };

  # add flakes feature
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  services.xserver.displayManager.autoLogin.enable = false;

  # Enable CUPS to print documents.
  services.printing = {
    enable = !runHeadless;
    drivers = with pkgs; [
      cnijfilter2 # Canon Pixma Drivers
      gutenprint
      epson-escpr # Epson Drivers
    ];
  };
  # Scanner Support
  hardware.sane.enable = !runHeadless;

  # Use zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  #  promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  environment.shells = [ pkgs.zsh ];  
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  services.xserver.displayManager.autoLogin.user = userName;

  users.users."${userName}" = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ 
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager" # Allow changing the network settings
      "audio" "video" # For sound settings
      "scanner" # For scanners
      "lp" # For scanners
      "dialout" # for serial ports
    ];
    # Set password hash, generated with 'mkpasswd -m sha-512 -s':
    hashedPassword = myTools.getSecret ./. "password.nix";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}

