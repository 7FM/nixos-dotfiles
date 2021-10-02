{ config, pkgs, lib, ... }:

{

  # Basic hardware settings
  hardware.opengl = {
    enable = true;
    driSupport = true;
    # On 64-bit systems, if you want OpenGL for 32-bit programs such as in Wine, you should also set the following:
    driSupport32Bit = true;
  };

}
