{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    gitAndTools.git-crypt
  ];

  programs.git = {
    enable = true;
    userName = "7FM";
    userEmail = "41307817+7FM@users.noreply.github.com";

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
    };

    delta = {
      enable = true;
    };

    lfs = {
      enable = true;
    };
  };
}
