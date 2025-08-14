{ lib
, buildPythonPackage
, fetchPypi
, requests
, lxml
, pythonOlder
, black
, isort
, responses
, tox
, setuptools
}:

buildPythonPackage rec {
  pname = "compal";
  version = "0.5.1";
  pyproject = true;
  build-system = [ setuptools ];

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-2MaJrv+n1Q4Pu90NFfLg15Q9sIHHjJ5L9lugnLONR/Q=";
  };

  propagatedBuildInputs = [
    requests
    lxml
  ];

  nativeCheckInputs = [
    black
    isort
    responses
    tox
  ];

  # no tests are present
  doCheck = true;

  pythonImportsCheck = [ "compal" ];

  meta = with lib; {
    description = "Python interface for the Ziggo Connect Box/Compal CH7465LG";
    longDescription = ''
      This repository contains a simple api to wrap the web interface of the Ziggo Connect Box (i.e. the Compal CH7465LG).
    '';
    homepage = "https://github.com/ties/compal_CH7465LG_py";
    license = with licenses; [ mit ];
    #maintainers = with maintainers; [ ];
  };
}
