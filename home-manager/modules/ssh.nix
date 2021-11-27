{ config, pkgs, lib, ... }:

let
  tools = import ../common/lib { inherit config pkgs lib; };

  enable = config.custom.hm.modules.ssh.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      sshuttle
      sshfs
    ];

    programs.ssh = {
      enable = true;
      matchBlocks = tools.getSecret ../configs "sshConfig.nix" { inherit config pkgs lib; };
    };
  };
}
