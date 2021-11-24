hm: deviceName:
{ config, pkgs, lib, ... }:

{
  imports = [
    # device specifics
    # TODO is there a way to concat a string to a path?
    (if hm then ../home-manager/devices/virtualbox.nix else ../nixos/devices/virtualbox.nix )
    ./settings/virtualbox.nix
    (if hm then ../home-manager/devices/desktop.nix else ../nixos/devices/desktop.nix )
    ./settings/desktop.nix
    (if hm then ../home-manager/devices/lenovo_laptop.nix else ../nixos/devices/lenovo_laptop.nix )
    ./settings/lenovo_laptop.nix
  ];

  options.custom = with lib; {
    device = mkOption {
      type = types.nullOr (types.enum [ "virtualbox" "lenovo_laptop" "desktop" ]);
      default = null;
      description = ''
        Specifies the custom device configuration to use!
      '';
    };

    gui = mkOption {
      type = types.nullOr (types.enum [ "x11" "wayland" "headless" "hm-wayland" ]);
      default = null;
      description = ''
        Specifies the user frontend to use.
      '';
    };

    cpu = mkOption {
      type = types.nullOr (types.enum [ "amd" "intel" "generic" ]);
      default = null;
      description = ''
        Specifies cpu brand in use, to apply microcode patches or cpu specific settings!
      '';
    };

    gpu = mkOption {
      type = types.nullOr (types.enum [ "amd" "intel" "nvidia" "generic" ]);
      default = null;
      description = ''
        Specifies gpu brand in use, to apply specific settings!
      '';
    };
  };

  config = {
    custom.device = deviceName;

    assertions = [
      {
        assertion = config.custom.device != null;
        message = "A predefined device configuration must be specified!";
      }
      {
        assertion = config.custom.gui != null;
        message = "A user frontend must be specified!";
      }
      {
        assertion = config.custom.gpu != null;
        message = "A gpu must be specified!";
      }
      {
        assertion = config.custom.cpu != null;
        message = "A cpu must be specified!";
      }
    ];
  };
}
