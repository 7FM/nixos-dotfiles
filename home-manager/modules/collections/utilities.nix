{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Utilities
    wget
    htop
    screen
    gparted
    zip
    unzip
    sxiv # Image viewer
    nnn # CLI file browser
    moc # CLI audio player
    unixtools.xxd # hexeditor
    #nmap
    nmap-graphical
    x2goclient
    syncthing
    speedtest-cli
    usbutils
    pciutils
    inetutils
    # Autoload shell.nix files
    direnv
  ];

  # Direnv shell integration: https://direnv.net/docs/hook.html
  programs.zsh.initExtra = ''
    eval "$(direnv hook zsh)"
  '';

  # Config for htop
  home.file.".config/htop".source = ../../configs/htop;

  # Plugins for nnn
  home.file.".config/nnn/plugins".source = ../../configs/nnn/plugins;
  # Enable certain plugins
  home.sessionVariables = {
    NNN_PLUG = "v:imgview;q:mocq;e:suedit;c:rsynccp;h:hexview";
  };
}
