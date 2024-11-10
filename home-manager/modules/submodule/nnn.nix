{ config, pkgs, lib, ... }:

let 
  bookmarks = [
    { 
      hotkey = "D";
      path = "${config.home.homeDirectory}/Downloads";
    }
    {
      hotkey = "S";
      path = "${config.home.homeDirectory}/screenshots";
    }
    {
      hotkey = "d";
      path = "${config.home.homeDirectory}/docs";
    }
    {
      hotkey = "s";
      path = "${config.home.homeDirectory}/docs/Studium";
    }
  ];

  toGtkBookmarks = bList: map (b: "file://${b.path}") bList;
  toNNNBookmarks = bList: builtins.listToAttrs (map (b: { name = b.hotkey; value = b.path; }) bList);
in {
  gtk.gtk3.bookmarks = toGtkBookmarks bookmarks;

  # NNN: CLI file browser 
  programs.nnn = {
    enable = true;
    package = pkgs.nnn.override { withNerdIcons = true; };

    bookmarks = toNNNBookmarks bookmarks;

    # Extra packages that are used for i.e. plugins
    extraPackages = with pkgs; [
      nsxiv # Image viewer
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

  xdg.desktopEntries.nnn = {
    type ="Application";
    name = "nnn";
    comment = "Terminal file manager";
    exec = "nnn %f";
    terminal = true;
    noDisplay = true;
    icon = "nnn";
    mimeType = [
      "inode/directory"
      "application/octet-stream"
      "multipart/x-zip"
      "application/zip"
      "application/zip-compressed"
      "application/x-zip-compressed"
      "application/x-gtar"
      "application/x-tar"
      "application/gzip"
      "application/x-xz"
      "application/x-7z-compressed"
      "application/x-rar-compressed"
      "application/x-bzip"
      "application/x-bzip2"
    ];
    categories = [" System" "FileTools" "FileManager" "ConsoleOnly"];
    # Keywords=File;Manager;Management;Explorer;Launcher
  };

  xdg.mimeApps = {
    associations.added = {
      "image/svg+xml" = "nsxiv.desktop";
    };
    defaultApplications = {
      "inode/directory" = [ "nnn.desktop" ];
    };
  };

  # Enable cd on exit
  xdg.configFile."nnn/quitcd.bash_zsh".source = ../../configs/nnn/quitcd.bash_zsh;

  # initExtra and initExtraFirst are already in use... TODO find better solution!
  programs.zsh.initExtraBeforeCompInit = ''
    if [ -f "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/nnn/quitcd.bash_zsh" ]; then
      source "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/nnn/quitcd.bash_zsh"
    fi
  '';
}
