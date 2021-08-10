{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    sshuttle
    sshfs
  ];

  programs.ssh = {
    enable = true;
    startAgent = true;
    matchBlocks = import ../configs/secrets/sshConfig.nix;
  };
}
