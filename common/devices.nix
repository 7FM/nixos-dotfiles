{ config, pkgs, lib, ... }:

{
  imports = [
    # device specifics
    ../devices/virtualbox.nix
    ../devices/desktop.nix
    ../devices/lenovo_laptop.nix
  ];

  options.custom = with lib; {
    device = mkOption {
      type = types.nullOr (types.enum [ "virtualbox" "lenovo_laptop" "desktop" ]);
      default = null;
      description = ''
        Specifies the custom device configuration to use!
      '';
    };
  };

  config = {
    # custom.device = "virtualbox";
    # custom.device = "desktop";
    # custom.device = "lenovo_laptop";
  };
}
