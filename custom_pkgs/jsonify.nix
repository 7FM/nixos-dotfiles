{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "jsonify";
  version = "0.5";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-80ADJ1NXdXXpd3g1gJsoP9ybJRhn1dVgA4kTFkf4v+E=";
  };

  # no tests are present
  doCheck = true;

  pythonImportsCheck = [ "jsonify" ];
}
