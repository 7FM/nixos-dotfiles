{ lib
, buildPythonPackage
, fetchPypi
, setuptools
}:

buildPythonPackage rec {
  pname = "rgbxy";
  version = "0.5";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-eKCZ9fjTDILpXxlBhQvEnkJknWvqyPluOjAel0N9bTA=";
  };

  # no tests are present
  doCheck = true;

  pyproject = true;
  build-system = [ setuptools ];

  pythonImportsCheck = [ "rgbxy" ];
}
