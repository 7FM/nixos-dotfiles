{ config, pkgs, lib, osConfig, ... }:
let
  cfg = osConfig.custom.hm.modules.alacritty;

  enable = cfg.enable;
  usesVirtualbox = cfg.virtualboxWorkaround;

  vbox_fix = pkgs.callPackage ({symlinkJoin, writeShellScriptBin, alacritty}:
    let
      wrapped = writeShellScriptBin "alacritty" ''
        exec LIBGL_ALWAYS_SOFTWARE=1 ${alacritty}/bin/alacritty "$@"
      '';
    in symlinkJoin rec {
      inherit (alacritty) name pname;

      paths = [
        wrapped
        alacritty
      ];
    }) {};

  package = if usesVirtualbox then vbox_fix else pkgs.alacritty;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      package
    ];

    xdg.configFile."alacritty/alacritty.yml".source = ../configs/terminal/alacritty.yml;
  };
}
