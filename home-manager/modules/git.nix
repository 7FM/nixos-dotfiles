{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.modules.git.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      gitAndTools.git-crypt
    ];

    programs.git = {
      enable = true;
      userName = "7FM";
      userEmail = "41307817+7FM@users.noreply.github.com";

      extraConfig = {
        pull = {
          rebase = false; # merge
        };
      };

      aliases = {
        a = "add";
        c = "commit";
        d = "diff";
        s = "status";
        b = "branch";
        l = "log";
        m = "merge";
        ch = "checkout";
        sh = "show";
        pl = "pull";
        ps = "push";
        rb = "rebase";
        r = "restore --staged";
      };

      delta = {
        enable = true;
      };

      lfs = {
        enable = true;
      };
    };
  };
}
