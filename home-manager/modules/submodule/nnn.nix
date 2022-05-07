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

  xdg.desktopEntries.nnn = {
    type ="Application";
    name = "nnn";
    comment = "Terminal file manager";
    exec = "nnn %f";
    terminal = true;
    icon = "nnn";
    mimeType = [ "inode/directory" ];
    categories = [" System" "FileTools" "FileManager" "ConsoleOnly"];
    # Keywords=File;Manager;Management;Explorer;Launcher
  };

  xdg.desktopEntries.sxiv = {
    type ="Application";
    name = "sxiv";
    comment = "Terminal image viewer";
    exec = "sxiv %f";
    terminal = true;
    icon = "sxiv";
    mimeType = [
      "image/bmp"
      "image/g3fax"
      "image/gif"
      "image/x-fits"
      "image/x-pcx"
      "image/x-portable-anymap"
      "image/x-portable-bitmap"
      "image/x-portable-graymap"
      "image/x-portable-pixmap"
      "image/x-psd"
      "image/x-sgi"
      "image/x-tga"
      "image/x-xbitmap"
      "image/x-xwindowdump"
      "image/x-xcf"
      "image/x-compressed-xcf"
      "image/x-sun-raster"
      "image/tiff"
      "image/jpeg"
      "image/x-psp"
      "image/png"
      "image/x-icon"
      "image/x-xpixmap"
      "image/x-exr"
      "image/webp"
      "image/x-webp"
      "image/heif"
      "image/heic"
      "image/avif"
      "image/svg+xml"
      "image/x-wmf"
      "image/jp2"
      "image/x-xcursor"
      "image/openraster"
    ];
    categories = [" System" "FileTools" "FileManager" "ConsoleOnly"];
    # Keywords=File;Manager;Management;Explorer;Launcher
  };

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "nnn.desktop" ];
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
