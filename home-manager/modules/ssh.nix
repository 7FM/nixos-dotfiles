{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    sshuttle
    sshfs
  ];

  programs.ssh = {
    enable = true;
    matchBlocks = import ../configs/secrets/sshConfig.nix{ config = config; pkgs = pkgs; lib = lib; };
  };
}
