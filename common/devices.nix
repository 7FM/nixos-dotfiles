deviceName:
{
  config,
  pkgs,
  lib,
  ...
}:

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

    gui = {
      headless = mkEnableOption "headless mode (no GUI)";
      sway = mkEnableOption "Sway window manager (home-manager managed)";
      hyprland = mkEnableOption "Hyprland compositor (home-manager managed)";
      x11 = mkEnableOption "X11 desktop (GNOME)";
    };

    cpu = mkOption {
      type = types.nullOr (
        types.enum [
          "amd"
          "intel"
          "generic"
        ]
      );
      default = null;
      description = ''
        Specifies cpu brand in use, to apply microcode patches or cpu specific settings!
      '';
    };

    gpu = mkOption {
      type = types.nullOr (
        types.enum [
          "amd"
          "intel"
          "nvidia"
          "generic"
        ]
      );
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
      type = types.enum [
        "none"
        "pulseaudio"
        "pipewire"
      ];
      default = "pipewire";
      description = ''
        Specifies the audio backend to use.
      '';
    };

    hm =
      let
        mkEnableDefaultTrueOption = name: mkEnableOption name // { default = true; };
      in
      {
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
          calendar.enable = mkEnableOption "the calendar module";
          email.enable = mkEnableOption "the email module";
          easyeffects.enable = mkEnableOption "the easyeffects module";
          git = {
            enable = mkEnableOption "the git module";
            identity_scripts.enable = mkEnableOption "the git author set/fix scripts";
          };
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
            touchpad = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Specifies the id of the laptop's touchpad.
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
          hyprland = {
            laptopDisplay = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Specifies the name of the laptop display (e.g., eDP-1).
                Or null if the computer is not a laptop.
              '';
            };
            touchpad = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Specifies the name of the laptop's touchpad (from hyprctl devices).
              '';
            };
            monitors = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    name = mkOption {
                      type = types.str;
                      description = "Monitor name (e.g., eDP-1, HDMI-A-1).";
                    };
                    resolution = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Resolution string (e.g., 1920x1080@60), or null for 'preferred'.";
                    };
                    position = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Position string (e.g., 0x0), or null for 'auto'.";
                    };
                    scale = mkOption {
                      type = types.number;
                      default = 1;
                      description = "Display scale factor.";
                    };
                    primary = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Whether this is the primary monitor.";
                    };
                  };
                }
              );
              default = [ ];
              description = "List of monitor configurations for Hyprland.";
            };
            extraConfig = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Additional Hyprland config lines appended to extraConfig.
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
        assertion =
          config.custom.gui.headless
          || config.custom.gui.sway
          || config.custom.gui.hyprland
          || config.custom.gui.x11;
        message = "At least one GUI mode or headless must be enabled!";
      }
      {
        assertion =
          !(config.custom.gui.headless && (config.custom.gui.sway || config.custom.gui.hyprland || config.custom.gui.x11));
        message = "gui.headless conflicts with gui.sway, gui.hyprland, and gui.x11!";
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
