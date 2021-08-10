{ config, pkgs, lib, ... }:

{

  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraConfig = "colorscheme gruvbox";
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

}
