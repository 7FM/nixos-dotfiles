{
  stdenv,
  fetchgit,
  lib,
  meson,
  ninja,
  libcamera,
  libpisp,
  python3,
  python3Packages,
  pkg-config,
  boost,
  cmake,
  #, libav
  ffmpeg,
  libexif,
  libjpeg,
  libtiff,
  libpng,
  libdrm,
  opencv,
}:

stdenv.mkDerivation rec {
  pname = "rpicam-apps";
  version = "1.11.1";

  src = fetchgit {
    url = "https://github.com/raspberrypi/rpicam-apps";
    rev = "v${version}";
    hash = "sha256-hVoKbvWFeramPkHuibJwUgFOPS9v588+K8828a1fNnA=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    patchShebangs utils/
  '';

  strictDeps = true;

  buildInputs = [
    libcamera
    libpisp
    #libav
    ffmpeg
    libexif
    libjpeg
    libtiff
    libpng
    libdrm
    opencv
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
    cmake
    boost.dev
  ];

  mesonFlags = [
    "-Denable_libav=disabled"
    "-Denable_egl=disabled"
    "-Denable_qt=disabled"
    "-Denable_hailo=disabled"
    "-Denable_opencv=enabled"
    "-Denable_imx500=false"
  ];

  env = {
    # Fixes error on a deprecated declaration
    NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations -I${lib.getDev boost}/include -L${lib.getDev boost}/lib";

    BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
    BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";
  };
}
