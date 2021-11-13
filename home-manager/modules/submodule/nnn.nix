{ config, pkgs, lib, ... }:

{
  # NNN: CLI file browser 
  programs.nnn = {
    enable = true;
    package = pkgs.nnn.override { withNerdIcons = true; };

    bookmarks = {
      d = "~/docs";
      D = "~/Downloads";
      s = "~/docs/Studium";
    };

    # Extra packages that are used for i.e. plugins
    extraPackages = with pkgs; [
      sxiv # Image viewer
      moc # CLI audio player
      unixtools.xxd # hexeditor
    ];

    plugins = {
      mappings = {
          v = "imgview";
          q = "mocq";
          e = "suedit";
          c = "rsynccp";
          h = "hexview";
      };

  #      src = (pkgs.fetchFromGitHub {
  #        owner = "jarun";
  #        repo = "nnn";
  #        rev = "v4.3";
  #        sha256 = "sha256-Hpc8YaJeAzJoEi7aJ6DntH2VLkoR6ToP6tPYn3llR7k=";
  #      }) + "/plugins";
      src = (pkgs.nnn.src) + "/plugins";
    };
  };
  # Enable cd on exit
  home.file.".config/nnn/quitcd.bash_zsh".source = ../../configs/nnn/quitcd.bash_zsh;
  # initExtra and initExtraFirst are already in use... TODO find better solution!
  programs.zsh.initExtraBeforeCompInit = ''
    if [ -f "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/nnn/quitcd.bash_zsh" ]; then
    source "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/nnn/quitcd.bash_zsh"
    fi
  '';
}
