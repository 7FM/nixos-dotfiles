{ config, pkgs, lib, ... }:

let
  enable = config.custom.hm.collections.utilities.enable;
in {
  config = lib.mkIf enable (lib.mkMerge [{
    home.packages = with pkgs; [
      # Utilities
      wget
      htop
      iotop
      screen
      zip
      unzip
      nfs-utils # Utilities to mount NFS shares
      speedtest-cli
      arp-scan
      usbutils
      pciutils
      inetutils
    ];

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;
    };

    programs.zsh.initExtra = ''
nixify() {
  if [ ! -e ./.envrc ]; then
    echo "use nix" > .envrc
    direnv allow
  fi
  if [[ ! -e shell.nix ]] && [[ ! -e default.nix ]]; then
    cat > default.nix <<'EOF'
with import <nixpkgs> {};
mkShell {
  nativeBuildInputs = [
    bashInteractive
  ];
}
EOF
    ${EDITOR:-vim} default.nix
  fi
}

flakifiy() {
  if [ ! -e flake.nix ]; then
    nix flake new -t github:nix-community/nix-direnv .
  elif [ ! -e .envrc ]; then
    echo "use flake" > .envrc
    direnv allow
  fi
  ${EDITOR:-vim} flake.nix
}
    '';

    # Config for htop
    xdg.configFile."htop/htoprc".source = ../../configs/htop/htoprc;

  } (import ../submodule/nnn.nix { inherit config pkgs lib; })]);
}
