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
        b = "branch";
        c = "commit";
        ch = "checkout";
        d = "diff";
        dc = "diff --cached";
        l = "log";
        m = "merge";
        s = "status";
        sh = "show";
        st = "stash";
        sp = "stash pop";
        pl = "pull";
        ps = "push";
        r = "restore --staged";
        rb = "rebase";
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
