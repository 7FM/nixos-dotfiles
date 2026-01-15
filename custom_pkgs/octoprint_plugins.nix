{ lib
, config
, fetchFromGitHub
, fetchpatch
, setuptools
}:

self: super:
let
  buildPlugin = args: self.buildPythonPackage (args // {
    pname = "octoprint-plugin-${args.pname}";
    inherit (args) version;
    propagatedBuildInputs = (args.propagatedBuildInputs or [ ]) ++ [ self.octoprint ];
    # none of the following have tests
    doCheck = false;
    pyproject = true;
    build-system = [ setuptools ];
  });
in
{
  inherit buildPlugin;

  bltouch = buildPlugin rec {
    pname = "BLTouch";
    version = "0.3.4";
    src = fetchFromGitHub {
      owner = "jneilliii";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-fQdJqmy6/2bOnCMeEB9y2UbRc3Q4rSc/lZQ4eNqEKnA=";
    };
    meta = with lib; {
      description = "Simple plugin to add BLTouch controls to the Control tab";
      homepage = "https://github.com/jneilliii/OctoPrint-BLTouch";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  heatertimeout = buildPlugin rec {
    pname = "HeaterTimeout";
    version = "0.0.4";
    src = fetchFromGitHub {
      owner = "Andy-ch";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-F3QZ/VhjO7eo5xGxVuOPwbrm24+zor4CUu7+JmXzDXw=";
    };
    meta = with lib; {
      description = "Automatically shut off heaters if no print has been started";
      homepage = "https://github.com/Andy-ch/OctoPrint-HeaterTimeout";
      license = licenses.asl20;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  taborder = buildPlugin rec {
    pname = "TabOrder";
    version = "0.5.12";
    src = fetchFromGitHub {
      owner = "jneilliii";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-o1mkDsgpRh6PsDl9U60nQJZ3B8fSz/xmscfH81BULs0=";
    };
    meta = with lib; {
      description = "Simple plugin to allow the ordering of tabs within OctoPrint";
      homepage = "https://github.com/jneilliii/OctoPrint-TabOrder";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  webcamtab = buildPlugin rec {
    pname = "WebcamTab";
    version = "0.3.1";
    src = fetchFromGitHub {
      owner = "gruvin";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-BoHghhWnZCRjq5eAxFV3H7Wm0UVFV2nHNO4Qmz1mjuo=";
    };
    meta = with lib; {
      description = "Moves the webcam stream from Control tab to its own Webcam tab";
      homepage = "https://github.com/gruvin/OctoPrint-WebcamTab";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  uploadanything = buildPlugin rec {
    pname = "UploadAnything";
    version = "1.0.1";
    src = fetchFromGitHub {
      owner = "rlogiacco";
      repo = pname;
      rev = "560d230352e94fbf37c57476a60978713321643e";
      sha256 = "sha256-52Jq53nqJ0QbOUKvs3fPls5G+ERR3nre62nXb27R27Y=";
    };
    meta = with lib; {
      description = "Allows custom file types to be uploaded via the web interface";
      homepage = "https://github.com/rlogiacco/UploadAnything";
      license = licenses.asl20;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  multipleupload = buildPlugin rec {
    pname = "MultipleUpload";
    version = "1.1.0";
    src = fetchFromGitHub {
      owner = "eyal0";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-5HeBOT4ze106IVCdwE6uf8GwMhqYMaJHHD7Owbi0WuM=";
    };
    meta = with lib; {
      description = "Allow uploading multiple files at once";
      homepage = "https://github.com/eyal0/OctoPrint-MultipleUpload";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  multilineterminal = buildPlugin rec {
    pname = "MultiLineTerminal";
    version = "0.1.5";
    src = fetchFromGitHub {
      owner = "jneilliii";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-8TJkWCYTaGO9v0fw4mYQLjJUgBRcJyWNn9AupsyxkiY=";
    };
    meta = with lib; {
      description = "Makes the terminal input a multi line text area";
      homepage = "https://github.com/jneilliii/OctoPrint-MultiLineTerminal";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  floatingnavbar = buildPlugin rec {
    pname = "FloatingNavbar";
    version = "0.3.7";
    src = fetchFromGitHub {
      owner = "jneilliii";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-sSs/hQMP4ivjA56k3OEuEZEIrAsMxhHt+gYWSiobgjY=";
    };
    meta = with lib; {
      description = "Make the navbar float/stick to the top of the page";
      homepage = "https://github.com/jneilliii/OctoPrint-FloatingNavbar";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  excluderegion = buildPlugin rec {
    pname = "ExcludeRegionPlugin";
    version = "0.3.2";
    src = fetchFromGitHub {
      owner = "bradcfisher";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-YS67lq7Y15EXuJxpZ9VE0PsveYmtIEzRMHRn1GNMJBU=";
    };
    meta = with lib; {
      description = "Adds the ability to prevent printing within rectangular or circular regions of the currently active gcode file";
      homepage = "https://github.com/bradcfisher/OctoPrint-ExcludeRegionPlugin";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  enclosure = buildPlugin rec {
    pname = "enclosure";
    version = "4.13.2";
    src = fetchFromGitHub {
      owner = "vitormhenrique";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-lfPh7Uq/NUMo/tC3OIkr/LUsDzw1ihw38yXoRNikOO0=";
    };
    propagatedBuildInputs = with super; [ rpi-gpio smbus2 gpiozero ];
    meta = with lib; {
      description = "Control printer environment (Temperature control / Lights / Fans and Filament Sensor) using Raspberry Pi GPIO";
      homepage = "https://github.com/vitormhenrique/OctoPrint-Enclosure";
      license = licenses.gpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  emergencystopsimplified = buildPlugin rec {
    pname = "Emergency_stop_simplified";
    version = "0.1.1";
    src = fetchFromGitHub {
      owner = "Mechazawa";
      repo = "${pname}";
      rev = "${version}";
      sha256 = "sha256-41pxUu6OHp0im/2n1Z9JuBN3zzoGlY2qqFUx9/srfAM=";
    };
    propagatedBuildInputs = with super; [ rpi-gpio ];
    meta = with lib; {
      description = "This plugin reacts to a switch or button, if triggered (switch open) it issues M112 command to printer";
      homepage = "https://github.com/Mechazawa/Emergency_stop_simplified";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  bedlevelingwizard = buildPlugin rec {
    pname = "BedLevelingWizard";
    version = "0.2.5";
    src = fetchFromGitHub {
      owner = "jneilliii";
      repo = "OctoPrint-${pname}";
      rev = version;
      sha256 = "sha256-3CSCGUWSsWoP2LuoFqCZXku5BqVdbHV9c1+Z4VCdzhs=";
    };
    meta = with lib; {
      description = "Plugin to aid in the process of manually leveling your bed";
      homepage = "https://github.com/jneilliii/OctoPrint-BedLevelingWizard";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  autoscroll = buildPlugin rec {
    pname = "Autoscroll";
    version = "0.0.3";
    src = fetchFromGitHub {
      owner = "MoonshineSG";
      repo = "OctoPrint-${pname}";
      rev = "${version}";
      sha256 = "sha256-SJD5aYuxrJLOrs1LybImgYI50dbrVrpMHwPrYjNhYXk=";
    };
    meta = with lib; {
      description = "Turn on/off terminal autoscroll when scrolling up/down";
      homepage = "https://github.com/MoonshineSG/OctoPrint-Autoscroll";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
  arc_welder = buildPlugin rec {
    pname = "ArcWelderPlugin";
    version = "1.0.0";
    src = fetchFromGitHub {
      owner = "FormerLurker";
      repo = "${pname}";
      rev = "${version}";
      sha256 = "sha256-FFYeTP4v9hvL0T67c+hITbrS9la51tGMAyW89hWmpus=";
    };
    patches = [
      (fetchpatch {
        url = "https://github.com/7FM/ArcWelderPlugin/commit/d46382ef2eea16aab048b9368b48044a45de4397.patch";
        sha256 = "sha256-hjly1oJJtMiHnIcfZXEdfnmKE5kIWWsKkCHNtA6+Q9A=";
      })
      (fetchpatch {
        url = "https://github.com/7FM/ArcWelderPlugin/commit/7337b8cf65ed0e8dd2185434e8bb4b8b1a31a959.patch";
        sha256 = "sha256-lBewnOxPzdmCS2GfRMT+3hO25l0SH70HJd26BeutEqo=";
      })
      (fetchpatch {
        url = "https://github.com/7FM/ArcWelderPlugin/commit/04c951f3a1ccd9ea1185a8a04e535b080e8e8a79.patch";
        sha256 = "sha256-dmmEzhy17huclo1wOubpBUDc2L7vqEU5b/6a5loM47A=";
      })
    ];
    meta = with lib; {
      description = "Anti-Stutter and GCode Compression. Replaces G0/G1 with G2/G3 where possible";
      homepage = "https://github.com/FormerLurker/ArcWelderPlugin";
      license = licenses.agpl3Only;
      # maintainers = with maintainers; [ _7FM ];
    };
  };
}
