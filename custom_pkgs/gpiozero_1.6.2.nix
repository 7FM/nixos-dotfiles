{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  sphinx-rtd-theme,
  sphinxHook,
  colorzero,
  mock,
  pythonOlder,
  pytestCheckHook,
  standard-pkg-resources,
}:

buildPythonPackage rec {
  pname = "gpiozero";
  version = "1.6.2";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "gpiozero";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-dmFc3DNTlEajYQ5e8QK2WfehwYwAsWyG2cxKg5ykEaI=";
  };

  outputs = [
    "out"
    "doc"
  ];

  nativeBuildInputs = [
    sphinx-rtd-theme
    sphinxHook
  ];

  propagatedBuildInputs = [
    colorzero
    # gpiozero 1.6.2 still uses pkg_resources at runtime (devices.py, boards.py,
    # pins/mock.py); setuptools >= 81 no longer ships it
    standard-pkg-resources
  ];

  nativeCheckInputs = [
    mock
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "gpiozero"
    "gpiozero.tools"
  ];

  disabledTests = [
    # https://github.com/gpiozero/gpiozero/issues/1087
    "test_spi_hardware_write"
    "test_input_rotary_encoder_wait"
  ];

  meta = with lib; {
    description = "A simple interface to GPIO devices with Raspberry Pi";
    homepage = "https://github.com/gpiozero/gpiozero";
    changelog = "https://github.com/gpiozero/gpiozero/blob/v${version}/docs/changelog.rst";
    license = licenses.bsd3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ hexa ];
  };
}
