{ config, pkgs, lib, osConfig, ... }:

let
  myTools = pkgs.myTools { inherit osConfig; };
  enable = osConfig.custom.hm.modules.ssh.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      sshuttle
      sshfs
    ];

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = (myTools.getSecret ../configs "sshConfig.nix" { inherit config pkgs lib; }) // {
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          #serverAliveInterval = 0;
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      };
    };
  };
}
