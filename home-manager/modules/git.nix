{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.modules.git.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      git-crypt
    ];

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = "7FM";
          email = "41307817+7FM@users.noreply.github.com";
        };
        alias = {
          a = "add";
          b = "branch";
          c = "commit";
          ca = "commit --amend";
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

        pull = {
          rebase = false; # merge
        };
        push = {
          autoSetupRemote = true;
        };
      };

      lfs = {
        enable = true;
      };
    };
  };
}
