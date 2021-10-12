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
    openconnect
    openvpn
    x2goclient
    syncthing
    speedtest-cli
    usbutils
    pciutils
    inetutils
    idasen # Python API and CLI for the ikea IDÅSEN desk
    # Autoload shell.nix files
    direnv
  ];

  # Direnv shell integration: https://direnv.net/docs/hook.html
  programs.zsh.initExtra = ''
    eval "$(direnv hook zsh)"
  '';

  # Config for htop
  home.file.".config/htop/htoprc".source = ../../configs/htop/htoprc;

  # Config for idasen
  home.file.".config/idasen".source = ../../configs/secrets/idasen;

  # Plugins for nnn
  home.file.".config/nnn/plugins".source = ../../configs/nnn/plugins;
  # Enable certain plugins
  home.sessionVariables = {
    NNN_PLUG = "v:imgview;q:mocq;e:suedit;c:rsynccp;h:hexview";
  };
}
