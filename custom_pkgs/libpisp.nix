{ stdenv
, fetchgit
, lib
, meson
, pkg-config
, cmake
, nlohmann_json
, ninja
}:

stdenv.mkDerivation rec {
  pname = "libpisp";
  version = "1.0.7";

  src = fetchgit {
    url = "https://github.com/raspberrypi/libpisp";
    rev = "v${version}";
    hash = "sha256-Fo2UJmQHS855YSSKKmGrsQnJzXog1cdpkIOO72yYAM4=";
    # hash = "sha256-x0Im9m9MoACJhQKorMI34YQ+/bd62NdAPc2nWwaJAvM=";
  };

  # outputs = [ "out" "dev" ];

  # postPatch = ''
  #   patchShebangs utils/
  # '';

  strictDeps = true;

  buildInputs = [
    nlohmann_json
  ];

  nativeBuildInputs = [
    meson
    cmake
    pkg-config
    ninja
  ];

  mesonFlags = [
    "-Dlogging=disabled"
  #   "-Dv4l2=true"
  #   "-Dqcam=${if withQcam then "enabled" else "disabled"}"
  #   "-Dlc-compliance=disabled" # tries unconditionally to download gtest when enabled
  #   # Avoid blanket -Werror to evade build failures on less
  #   # tested compilers.
  #   "-Dwerror=false"
  #   # Documentation breaks binary compatibility.
  #   # Given that upstream also provides public documentation,
  #   # we can disable it here.
  #   "-Ddocumentation=disabled"
  ];

  # Fixes error on a deprecated declaration
  env.NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";
}
