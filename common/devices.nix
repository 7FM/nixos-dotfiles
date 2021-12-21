hm: deviceName:
{ config, pkgs, lib, ... }:

{
  imports = [
    # device specifics
    ((if hm then ../home-manager/devices else ../nixos/devices) + "/${deviceName}.nix")
    (./settings + "/${deviceName}.nix")
  ];

  options.custom = with lib; {
    useDummySecrets = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use dummy secrets so that no git crypt encryption is required.
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

    bluetooth = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable Bluetooth Support!
      '';
    };
  };

  config = {
    assertions = [
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
