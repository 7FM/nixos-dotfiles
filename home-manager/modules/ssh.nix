{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.ssh.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      sshuttle
      sshfs
    ];

    programs.ssh = {
      enable = true;
      matchBlocks = import ../configs/secrets/sshConfig.nix{ config = config; pkgs = pkgs; lib = lib; };
    };
  };
}
