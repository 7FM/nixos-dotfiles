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
      matchBlocks = myTools.getSecret ../configs "sshConfig.nix" { inherit config pkgs lib; };
    };
  };
}
