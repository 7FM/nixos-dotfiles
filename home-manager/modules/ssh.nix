{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  myTools = pkgs.myTools { inherit osConfig; };
  enable = osConfig.custom.hm.modules.ssh.enable;
in
{
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      sshuttle
      sshfs
    ];

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = (myTools.getSecret ../configs "sshConfig.nix" { inherit config pkgs lib; }) // {
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          #ServerAliveInterval = 0;
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
      };
    };
  };
}
