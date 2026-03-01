{ stdenv
, fetchgit
, lib
, meson
, ninja
, libcamera
, libpisp
, python3
, python3Packages
, pkg-config
, boost
, cmake
#, libav
, ffmpeg
, libexif
, libjpeg
, libtiff
, libpng
, libdrm
, opencv
}:

stdenv.mkDerivation rec {
  pname = "rpicam-apps";
  version = "1.5.1";

  src = fetchgit {
    url = "https://github.com/raspberrypi/rpicam-apps";
    rev = "v${version}";
    hash = "sha256-rl5GVigiZWXkpfIteRWUMjtCaPweXRWrBrZOjQ1hiU8=";
    # hash = "sha256-KH30jmHfxXq4j2CL7kv18DYECJRp9ECuWNPnqPZajPA=";
  };

  outputs = [ "out" "dev" ];

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
    "-Ddownload_hailo_models=false"
    "-Denable_egl=disabled"
    "-Denable_qt=disabled"
    "-Denable_hailo=disabled"
    "-Denable_opencv=enabled"
    # "-Ddownload_imx500_models=false"
    # "-Denable_imx500=false"
  ];

  env = {
    # Fixes error on a deprecated declaration
    NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations -I${lib.getDev boost}/include -L${lib.getDev boost}/lib";

    BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
    BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";
  };
}
