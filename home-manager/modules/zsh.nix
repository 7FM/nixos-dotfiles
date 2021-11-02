{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # needed for powerlevel10k
    (nerdfonts.override { fonts = [ "Meslo" ]; })
  ];

  # This enables discovering fonts that where installed with home.packages
  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
#      {
#        name = "powerlevel10k-config";
#        src = lib.cleanSource ./p10k-config;
#        file = "p10k.zsh";
#      }
    ];

    shellAliases = {
      "ll" = "ls -alh";
      ".." = "cd ..";
      "v" = "vim";
      "g" = "git";
      "gc" = "git-crypt";
      # Common typos...
      "hotp" = "htop";
      "got" = "git";
      "exot" = "exit";
      "ös" = "ls";
      "cd.." = "cd ..";
      # TERM variable is passed, so set it to a sane value before connecting
      "ssh" = "TERM=xterm ssh";
    };

    history = {
      share = false; # Each shell has its own history!
    };

    initExtra = ''
      bindkey "$terminfo[kRIT5]" forward-word
      bindkey "$terminfo[kLFT5]" backward-word
      bindkey "^R" history-incremental-search-backward
    '';

    initExtraFirst = ''
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "''\${XDG_CACHE_HOME:-''\$HOME/.cache}/p10k-instant-prompt-''\${(%):-%n}.zsh" ]]; then
  source "''\${XDG_CACHE_HOME:-''\$HOME/.cache}/p10k-instant-prompt-''\${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };

  #home.file.".zshrc".source = ../configs/shell/zsh/zshrc;
  home.file.".p10k.zsh".source = ../configs/shell/zsh/p10k.zsh;
}
