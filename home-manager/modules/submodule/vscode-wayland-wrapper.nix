{symlinkJoin, writeShellScriptBin, vscode}:

let
  wrapped = writeShellScriptBin "code" ''
    exec ${vscode}/bin/code --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
  '';
in symlinkJoin rec {
  inherit (vscode) name pname;

  paths = [
    wrapped
    vscode
  ];
}
