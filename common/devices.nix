deviceName:
{ config, pkgs, lib, ... }:

{
  imports = [
    # device specifics
    #((if hm then ../home-manager/devices else ../nixos/devices) + "/${deviceName}.nix")
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

    audio.backend = mkOption {
      type = types.enum [ "none" "pulseaudio" "pipewire" ];
      default = "pipewire";
      description = ''
        Specifies the audio backend to use.
      '';
    };

    hm = let
      mkEnableDefaultTrueOption = name: mkEnableOption name // { default = true; };
    in {
      modules = {
        alacritty = {
          enable = mkEnableOption "the alacritty module";
          virtualboxWorkaround = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Apply virtualbox specific workarounds for a correct operation.
            '';
          };
        };

        bash.enable = mkEnableDefaultTrueOption "the bash module";
        email.enable = mkEnableOption "the email module";
        easyeffects.enable = mkEnableOption "the easyeffects module";
        git.enable = mkEnableOption "the git module";
        gtk.enable = mkEnableOption "the gtk module";
        neovim.enable = mkEnableDefaultTrueOption "the neovim module";
        optimize_storage.enable = mkEnableOption "storage optimizations";
        qt.enable = mkEnableOption "the qt module";
        ssh.enable = mkEnableOption "the ssh module";
        xdg.enable = mkEnableDefaultTrueOption "the xdg module";
        zsh.enable = mkEnableDefaultTrueOption "the zsh module";

        sway = {
          laptopDisplay = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies the name of the laptop display.
              Or null in case the computer is no laptop.
            '';
          };
          disp1 = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies the name of the first display.
            '';
          };
          disp1_res = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies the resolution of the first display.
            '';
          };
          disp1_pos = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies the position of the first display.
            '';
          };
          disp2 = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies name of the second display.
              If only one display exists then the value of disp1 will be used.
            '';
          };
          disp2_res = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies the resolution of the second display.
            '';
          };
          disp2_pos = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies the position of the second display.
            '';
          };
          extraConfig = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specify additional config entries that are device specific.
            '';
          };
        };
        waybar = {
          hwmonPath = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Specifies the sys-fs path to an hwmon.
              This might be required if the default method can not determine the cpu temperature.
            '';
          };
          thermalZone = mkOption {
            type = types.nullOr types.ints.u8;
            default = null;
            description = ''
              Thermal zone to use for the waybar cpu temperature measurements.
            '';
          };
          gpu = {
            tempCmd = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The command to use for the gpu temperature measurements.
                I.e. "$\{pkgs.coreutils}/bin/cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input"
              '';
            };
            mhzFreqCmd = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The command to use to determine the gpu clock frequency in MHz.
                I.e. "$\{pkgs.coreutils}/bin/cat /sys/class/drm/card0/device/pp_dpm_sclk | $\{pkgs.gnugrep}/bin/egrep -o '[0-9]{0,4}Mhz \\W' | $\{pkgs.gnused}/bin/sed 's/Mhz \\*//'"
                or   "\$\{pkgs.coreutils}/bin/cat /sys/class/drm/card0/gt_cur_freq_mhz"
              '';
            };
            usageCmd = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The command to use to determine the gpu usage in percent.
                I.e. "$\{pkgs.coreutils}/bin/cat /sys/class/drm/card0/device/gpu_busy_percent"
              '';
            };
          };
        };
      };

      collections = {
        communication.enable = mkEnableOption "the communication collection";
        development.enable = mkEnableOption "the development collection";
        diyStuff.enable = mkEnableOption "the DIY stuff collection";
        gaming.enable = mkEnableOption "the gaming collection";
        gui_utilities.enable = mkEnableOption "the gui utilities collection";
        media.enable = mkEnableOption "the media collection";
        office.enable = mkEnableOption "the office collection";
        utilities.enable = mkEnableDefaultTrueOption "the utilities collection";
      };
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
