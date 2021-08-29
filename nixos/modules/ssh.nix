{ config, pkgs, lib, ... }:

let
  enable = config.custom.runSSHServer;
  runHeadless = config.custom.gui == "headless";
in {
  # Enable the OpenSSH daemon.
  services.openssh.enable = enable || runHeadless;
  services.openssh.ports = import ../secrets/sshPorts.nix;
  services.openssh.permitRootLogin = "no";
  services.openssh.passwordAuthentication = false;

  # Start ssh agent to manage the ssh keys
  programs.ssh.startAgent = !runHeadless;
}

