{ config, pkgs, lib, osConfig, ... }:

let
  enable = osConfig.custom.hm.modules.neovim.enable;
in {
  config = lib.mkIf enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      extraConfig = ''
        colorscheme gruvbox
        set number
      '';
      plugins = with pkgs.vimPlugins; [
        gruvbox
        nerdtree
        nerdcommenter
        ale
        vim-multiple-cursors
        # Syntax highlighting
        vim-nix
        vim-bsv
        verilog_systemverilog-vim
        vim-cpp-enhanced-highlight
      ];
    };

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
