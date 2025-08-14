{ lib
, python3Packages
, fetchFromGitHub
, fetchurl
, unzip

, jsonify
, rgbxy

, python3
, libfaketime
, openssl
# , libcoap
}:

python3Packages.buildPythonApplication rec {
  pname = "diyHue";
  version = "2025.01";
  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "a0f1584732b6eca3ae1ff7497c9a1039b9d396e6";
    sha256 = "sha256-qxS2Edd3o4oR9yFLeGagkDwACJCwMDS48O6i9HKWSMY=";
  };

  patches = [
    ./diyhue_shebang.patch
    ./diyhue_install_path.patch
    ./diyhue_no_updates.patch
    ./diyhue_no_update_check.patch
    ./diyhue_HueEmulator3_main.patch
  ];

  dependencies = with python3Packages; [
    astral
    ws4py
    requests
    paho-mqtt
    email-validator
    flask
    flask-login
    flask-restful
    flask-wtf
    flask-cors
    werkzeug
    wtforms
    pyyaml
    zeroconf
    yeelight
    python-kasa
    bleak
    jsonify
    rgbxy
  ];

  buildInputs = [ python3 libfaketime openssl ];

  postPatch = ''
    # Substitute the program names in the script with their Nix paths
    substituteInPlace BridgeEmulator/genCert.sh \
      --replace-fail "python3" "${lib.getExe python3}"
    substituteInPlace BridgeEmulator/genCert.sh \
      --replace-fail "faketime" "${lib.getExe' libfaketime "faketime"}"
    substituteInPlace BridgeEmulator/genCert.sh \
      --replace-fail "openssl " "${lib.getExe openssl} "
  '';

  preBuild =  let 
    diyhueUI = fetchurl {
      url = "https://github.com/diyhue/diyHueUI/releases/download/v2.0.2/DiyHueUI-release.zip";
      hash = "sha256-eWN4EU+XZv6q8hCaa7FP6oyGc9dnD78L7qpXP8sAQJU=";
    };
  in ''
    ${unzip}/bin/unzip -qo ${diyhueUI} -d diyhueUI
    cp -r diyhueUI/dist/index.html BridgeEmulator/flaskUI/templates/
    cp -r diyhueUI/dist/assets BridgeEmulator/flaskUI/
    rm -r diyhueUI

    cat > setup.py << EOF
from setuptools import setup
import os

def package_data_dirs(source, sub_folders):
    dirs = []

    for d in sub_folders:
        folder = os.path.join(source, d)
        if not os.path.exists(folder):
            continue

        for dirname, _, files in os.walk(folder):
            dirname = os.path.relpath(dirname, source)
            for f in files:
                dirs.append(os.path.join(dirname, f))

    return dirs

with open('requirements.txt') as f:
    install_requires = f.read().splitlines()

setup(
  name='diyHue',
  # packages=setuptools.find_packages(where="BridgeEmulator"),
  packages=['.', 'flaskUI', 'functions', 'lights', 'lights.protocols', 'sensors', 'HueObjects', 'services', 'configManager', 'logManager'],
  package_dir={"": "BridgeEmulator"},
  package_data={
      "": package_data_dirs(
          "BridgeEmulator", ['flaskUI', 'flaskUI/templates', 'flaskUI/assets', 'functions', 'lights', 'lights/protocols', 'sensors', 'HueObjects', 'services', 'configManager', 'logManager']
      ) + ['genCert.sh', 'openssl.conf']
  },
  version='2025.01',
  #author='...',
  #description='...',
  install_requires=install_requires,
  entry_points={
    'console_scripts': ['diyhue=HueEmulator3:main']
  },
)
EOF
  '';

#   nativeCheckInputs = [
#     libcoap
#     faketime
#   ];

  meta = with lib; {
    description = "diyHue provides a Ecosystem for several Smart Home Solutions.";
    longDescription = ''
      diyHue provides a Ecosystem for several Smart Home Solutions, eliminating the need for vendor specific Bridges and Hardware. Written in Python and Open Source, you are now able to import and control all your Lights and Sensors into one System.
    '';
    homepage = "https://diyhue.org/";
    license = with licenses; [ asl20 ];
    #maintainers = with maintainers; [ ];
    mainProgram = "diyhue";
  };
}
