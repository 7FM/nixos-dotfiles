{ config, pkgs, lib, ... }:

let 
  myTools = pkgs.myTools { inherit config pkgs lib; };
in {

  # Basic hardware settings
  hardware.opengl = {
    enable = true;
    driSupport = true;
    # On 64-bit systems, if you want OpenGL for 32-bit programs such as in Wine, you should also set the following:
    driSupport32Bit = pkgs.stdenv.isx86_64;
  };

}

