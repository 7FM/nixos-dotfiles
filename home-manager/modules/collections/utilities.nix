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
    jmtpfs # For MTP connection with an android phone
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
}
