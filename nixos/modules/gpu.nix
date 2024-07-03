{ config, pkgs, lib, ... }:

let 
  myTools = pkgs.myTools { osConfig = config; };
in {

  # Basic hardware settings
  hardware.graphics = {
    enable = true;
    # On 64-bit systems, if you want OpenGL for 32-bit programs such as in Wine, you should also set the following:
    enable32Bit = pkgs.stdenv.isx86_64;
  };

}

