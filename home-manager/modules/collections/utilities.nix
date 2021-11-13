{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.collections.utilities.enable;
in {
  config = lib.mkIf enable (lib.mkMerge [{
    home.packages = with pkgs; [
      # Utilities
      wget
      htop
      screen
      zip
      unzip
      jmtpfs # For MTP connection with an android phone
      #nmap
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
    home.file.".config/htop/htoprc".source = ../../configs/htop/htoprc;

  } (import ../submodule/nnn.nix { inherit config pkgs lib; })]);
}
