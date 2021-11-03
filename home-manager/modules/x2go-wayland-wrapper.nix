{symlinkJoin, writeShellScriptBin, x2goclient}:

let
  wrapped = writeShellScriptBin "x2goclient" ''
    QT_QPA_PLATFORM=xcb exec ${x2goclient}/bin/x2goclient
  '';
in symlinkJoin rec {
  inherit (x2goclient) name pname;

  paths = [
    wrapped
    x2goclient
  ];
}
