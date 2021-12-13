{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hm.modules;

  laptopDisplay = cfg.sway.laptopDisplay;
  disp1 = cfg.sway.disp1;
  disp2 = if cfg.sway.disp2 == null then disp1 else cfg.sway.disp2;
  usesVirtualbox = cfg.sway.virtualboxWorkaround;

  hwmonPath = cfg.waybar.hwmonPath; # sys-fs path, i.e. "/sys/class/hwmon/hwmon0/temp1_input"
  thermalZone = cfg.waybar.thermalZone; # Integer value

  #lockcmd = "swaylock -f -c 000000";
  lockcmd = "swaylock-fancy";
  #disableDisplayCmd = "timeout 600 'swaymsg \"output * dpms off\"'";
  disableDisplayCmd = "";
  enableDisplayCmd = "resume 'swaymsg \"output * dpms on\"'";

  enableSystemdSway = false;
  hmManageSway = config.custom.gui == "hm-wayland";
  enable = hmManageSway || (config.custom.gui == "wayland");

  # Waybar settings
  enableSystemdWaybar = false;
  waybarLaptopFeatures = laptopDisplay != null;
  desktop = laptopDisplay == null;
in {
  options.custom.hm.modules = with lib; {
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
      disp2 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specifies name of the second laptop display.
          If only one display exists then the value of disp1 will be used.
        '';
      };
      virtualboxWorkaround = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Apply virtualbox specific workarounds for a correct operation.
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
    };
  };

  config = lib.mkIf enable {

    assertions = [
      {
        assertion = config.custom.hm.modules.sway.disp1 != null;
        message = "If the system is not headless, then at least one display must be defined!";
      }
    ];

    home.packages = with pkgs; [
      # needed for waybar customization
      font-awesome
    ] ++ lib.optionals hmManageSway (import ../common/sway_extra_packages.nix { inherit pkgs; });

    wayland.windowManager.sway = (lib.optionalAttrs (!hmManageSway) { package = null; } ) // {
      enable = true;

      wrapperFeatures.gtk = true;
      systemdIntegration = enableSystemdSway;
      extraSessionCommands = import ../common/sway_extra_session_commands.nix;

      xwayland = hmManageSway;

      config = let
        mod = "Mod4";
        mod2 = if (mod == "Mod4") then "Mod1" else "Mod4";

        # Workspace labels
        workspaces = [
          rec { name = "1"; modifier = name; output = disp1; }
          rec { name = "2"; modifier = name; output = disp1; }
          rec { name = "3"; modifier = name; output = disp1; }
          rec { name = "4"; modifier = name; output = disp1; }
          rec { name = "5"; modifier = name; output = disp1; }
          rec { name = "6"; modifier = name; output = disp1; }
          rec { name = "7"; modifier = name; output = disp1; }
          rec { name = "8"; modifier = name; output = disp1; }
          rec { name = "9"; modifier = name; output = disp1; }
              { name = "10"; modifier = "0"; output = disp1; }

          { name = "11:A1"; modifier = "F1";   output = disp2; }
          { name = "12:A2"; modifier = "F2";   output = disp2; }
          { name = "13:A3"; modifier = "F3";   output = disp2; }
          { name = "14:A4"; modifier = "F4";   output = disp2; }
          { name = "15:A5"; modifier = "F5";   output = disp2; }
          { name = "16:A6"; modifier = "F6";   output = disp2; }
          { name = "17:A7"; modifier = "F7";   output = disp2; }
          { name = "18:A8"; modifier = "F8";   output = disp2; }
          { name = "19:A9"; modifier = "F9";   output = disp2; }
          { name = "20:A10"; modifier = "F10"; output = disp2; }
        ];

        createWsSwitchKeybindings = ws: map (
          w: { name = "${mod}+${w.modifier}"; value = "workspace ${w.name}"; }
        ) ws;
        createWsMoveKeybindings = ws: map (
          w: { name = "${mod}+Shift+${w.modifier}"; value = "move container to workspace ${w.name}"; }
        ) ws;

        createWsKeybindings = ws:
          builtins.listToAttrs ((createWsSwitchKeybindings ws) ++ (createWsMoveKeybindings ws));

        createWsOutputAssigns = ws: map (
          w: { workspace = w.name; output = w.output; }
        ) ws;
      in {
        fonts = {
          names = [ "FontAwesome5Free" ];
          style = "";
        };

        menu = "wofi --show=drun --lines=5 --prompt=\"\"";

        terminal = (if usesVirtualbox then "LIBGL_ALWAYS_SOFTWARE=1 " else "") + "alacritty";

        modifier = mod;

        keybindings = lib.mkOptionDefault ({
          # Brightness control
          "XF86MonBrightnessDown" = "exec \"brightnessctl set 2%-\"";
          "XF86MonBrightnessUp" = "exec \"brightnessctl set +2%\"";
          # Volume control
          "XF86AudioRaiseVolume" = "exec \"pactl set-sink-volume @DEFAULT_SINK@ +1%\"";
          "XF86AudioLowerVolume" = "exec \"pactl set-sink-volume @DEFAULT_SINK@ -1%\"";
          "XF86AudioMute" = "exec \"pactl set-sink-mute @DEFAULT_SINK@ toggle\"";
          # Lock hotkey
          "${mod}+${mod2}+l" = "exec ${lockcmd}";
          # Screenshots
          "Print" = "exec grim ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png";
          # Take a screenshot of a selected region
          "${mod}+Print" = "exec grim -g \"$(slurp)\" ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png";

          # workspace definitions:
        } // createWsKeybindings workspaces);

        startup = [
          # Authentication agent
          { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; always = false; }
          # Clipboard manager
          { command = "wl-paste -t text --watch clipman store"; always = false; }
          # Swayidle
          { command = "swayidle -w timeout 300 \"${lockcmd}\" ${disableDisplayCmd} ${enableDisplayCmd} before-sleep \"${lockcmd}\""; always = false; }
          # Import the most important environment variables into the D-Bus and systemd
          # user environments (e.g. required for screen sharing and Pinentry prompts):
          { command = "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"; always = false; }
        ] ++ lib.optional (disp1 != null) { command = "swaymsg focus output ${disp1}"; always = false; }
          ++ lib.optional (laptopDisplay != null) { command = "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/sway/scripts/clamshell_mode_fix.sh ${laptopDisplay}"; always = true; };

        bars = [
          {
            command = "${pkgs.waybar}/bin/waybar";
          }
        ];

        # Input settings
        input = {
          # TODO this should'nt be hardcoded!
          "2:7:SynPS/2_Synaptics_TouchPad" = {
            "dwt" = "enabled";
            "tap" = "enabled";
            "natural_scroll" = "enabled";
            "middle_emulation" = "enabled";
          };
        };

        # Output settings
        output = {
        # Does not work, dont know why
        #  "*" = {
        #    bg = "${XDG_CONFIG_HOME:-$HOME/.config}/sway/backgrounds/cheatsheet.jpg fit";
        #  };
        } // lib.mkIf desktop {
          #TODO these should'nt be hardcoded either!
          "${disp1}" = {
            res = "1920x1080@144Hz";
            pos = "0,0";
          };
          "${disp2}" = {
            res = "1920x1080";
            pos = "1920,0";
          };
        };

        # Default assign workspaces to outputs
        workspaceAutoBackAndForth = true;

        workspaceOutputAssign = if desktop then
          (createWsOutputAssigns workspaces)
        else [];

        gaps = {
          inner = 2;
          smartGaps = true;
          smartBorders = "on";
        };

        floating = {
          criteria = [
            { title = "^Steam - News"; class = "^Steam$"; }
            { title = "^Friends List$"; class = "^Steam$"; }
            { app_id = "^pavucontrol$"; }
            { app_id = "^nm-connection-editor$"; }
            { title = "^Print$"; }
            { title = "^wpa_gui$"; }
            # Zoom fixes
            { title = "^zoom$"; app_id = "$"; }
            { title = "^Settings$"; app_id = "$"; }
            { title = "^Polls$"; app_id = "$"; }
            { title = "^Select a window or an application that you want to share$"; app_id = "$"; }
          ];
        };

      };

      extraConfig = lib.optionalString (laptopDisplay != null) ''
        bindswitch --reload --locked lid:on output ${laptopDisplay} disable
        bindswitch --reload --locked lid:off output ${laptopDisplay} enable
      '' + ''
        output * bg ''\${XDG_CONFIG_HOME:-''\$HOME/.config}/sway/backgrounds/cheatsheet.jpg fit
      '';
    };

    # Waybar configuration
    programs.waybar = {
      enable = true;
      systemd.enable = enableSystemdWaybar;
      package = (pkgs.waybar.override { withMediaPlayer = true; });

      settings = [{
        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [
          "tray"
        ];
        modules-right = [
          "custom/spotify"
          "custom/media_firefox"
          "custom/mail"
          "network"
          "temperature"
          "cpu"
          "memory"
          #"custom/disk_home"
          "custom/disk_root"
        ] ++ (lib.optionals waybarLaptopFeatures [ 
          "backlight" 
        ]) ++ [
          "pulseaudio#out"
          "pulseaudio#in"
        ] ++ (lib.optionals waybarLaptopFeatures [ 
          "battery"
        ]) ++ [
          "idle_inhibitor"
          "clock"
          "custom/logout"
        ];

        modules = {
          # Modules configuration
          "sway/workspaces" = {
            disable-scroll = false;
            all-outputs = false;
            format = "{name}{icon}";
            # format = "{index}{icon}";
            format-icons = {
              "1:term" = " ";
              "2:web" = " ";
              "3:code" = " ";
              "4:music" = " ";
              "5:chat" = " ";
              "urgent" = " ";
              # "focused" = " ";
              "focused" = "";
              # "default" = " ";
              "default" = "";
            };
          };
          "sway/mode" = {
            format = "{}";
          };
          "custom/disk_home" = {
            format = "🏠 {}";
            interval = 180;
            exec = "df -h --output=avail $HOME | tail -1 | tr -d ' '";
            tooltip = false;
          };
          "custom/disk_root" = {
            format = "💽 {}";
            interval = 180;
            exec = "df -h --output=avail / | tail -1 | tr -d ' '";
            tooltip = false;
          };
          "custom/logout"  = {
            format = "";
            on-click = "wlogout";
            on-click-right = "wlogout";
            tooltip = false;
          };
          "temperature" = {
            critical-threshold = 80;
            # format-critical = "{temperatureC:>3}°C {icon}";
            format = "<span color='#e88939'>{icon}</span> {temperatureC}°C";
            format-icons = [
              "" # Icon: temperature-empty
              "" # Icon: temperature-quarter
              "" # Icon: temperature-half
              "" # Icon: temperature-three-quarters
              "" # Icon: temperature-full
            ];
            tooltip = false;
          } // (if (hwmonPath != null) then { hwmon-path = hwmonPath; } else {})
            // (if (thermalZone != null) then { thermal-zone = thermalZone; } else {});
          "cpu" = {
            format = "{usage:>3}%";
            tooltip = false;
            on-click = "alacritty --command htop";
            on-click-right = "alacritty --command htop";
          };
          "memory" = {
            format = " {used:0.1f}G";
            on-click = "alacritty --command htop";
            on-click-right = "alacritty --command htop";
          };
          "custom/mail" = {
            format = "📩 {}";
            interval = 180;
            exec = "notmuch count 'tag:flagged OR (tag:inbox AND NOT tag:killed AND NOT tag:spam AND tag:unread)'";
          };
          "network" = {
            family = "ipv4";
            # interface = "wlp2*"; # (Optional) To force the use of this interface
            format-wifi = "<span color='#589df6'></span> <span color='gray'>{essid}</span> <span color='#589df6'>{signalStrength}%</span> <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-ethernet = " {ifname}: {ipaddr} <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-linked = " {ifname} (No IP) <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-disconnected = "⚠ Disconnected";
            interval = 10;
            on-click = "nm-connection-editor";
            on-click-right = "nm-connection-editor";
            tooltip = false;
          };
          "backlight" = {
            device = "intel_backlight";
            # format = "{icon} {percent:>3}%";
            format = "{icon} {percent}%";
            format-icons = ["🔅" "🔆"];
          };
          "pulseaudio#out" = {
            # scroll-step = 1; # %, can be a float
            format = "{icon} {volume:>3}%";
            format-muted = "🔇   0%";
            format-bluetooth = "{icon} {volume:>3}%";
            format-bluetooth-muted = "🔇   0%";

            format-source = "";
            format-source-muted = "";

            format-icons = {
              "headphones" = "";
              "handsfree" = "";
              "headset" = "";
              "phone" = "";
              "portable" = "";
              "car" = "";
              "default" = ["🔈" "🔉" "🔊"];
            };
            on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
            on-click-right = "pavucontrol";
          };
          "pulseaudio#in" = {
            # scroll-step = 1; # %, can be a float
            format = "{format_source}";
            format-muted = "{format_source}";
            format-bluetooth = "{format_source}";
            format-bluetooth-muted = "{format_source}";

            format-source = " {volume:>3}%";
            format-source-muted = "   0%";

            on-click = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            on-click-right = "pavucontrol";
          };
          "clock" = {
            interval = 60;
            timezone = "Europe/Berlin";
            format = "⏰ {:%H:%M}";
            tooltip-format = "{:%d-%m-%Y | %H:%M}";
          };
          "battery" = {
            states = {
              "good" = 80;
              "warning" = 20;
              "critical" = 10;
            };
            format = "{icon}{capacity:>3}% {time}";
            format-charging = "{icon} <span color='#e88939'></span>{capacity:>3}% {time}";
            format-plugged =  "{icon} <span color='#e88939'></span>{capacity:>3}% {time}";
            # format-good = "", # An empty format will hide the module
            # format-full = "";
            format-icons = ["" "" "" "" ""];
          };
          "idle_inhibitor" = {
            format = "<span color='#589df6'>{icon}</span>";
            format-icons = {
              "activated" = "";
              "deactivated" = "";
            };
            on-click-right = "swaylock-fancy --daemonize";
          };
          "tray" = {
            # icon-size = 21;
            spacing = 10;
          };
          "custom/spotify" = {
            format = "{icon} {}";
            return-type = "json";
            max-length = 40;
            format-icons = {
              "spotify" = "";
              "firefox" = "";
              "default" = "🎜";
            };
            escape = true;
            # Filter player based on name
            exec = "waybar-mediaplayer.py --player spotify 2> /dev/null"; # Script in resources folder
            exec-if = "pgrep spotify";
            on-click = "playerctl -p spotify play-pause";
            on-click-right = "playerctl -p spotify next";
          };
          "custom/media_firefox" = {
            format = "{icon} {}";
            return-type = "json";
            max-length = 40;
            format-icons = {
              "spotify" = "";
              "firefox" = "";
              "default" = "🎜";
            };
            escape = true;
            # Filter player based on name
            exec = "waybar-mediaplayer.py --player firefox 2> /dev/null"; # Script in resources folder
            exec-if = "pgrep 'Web Content'";
            on-click = "playerctl -p firefox play-pause";
            on-click-right = "playerctl -p firefox next";
          };
          "mpd" = {
            format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ";
            format-disconnected = "Disconnected ";
            format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
            unknown-tag = "N/A";
            interval = 2;
            consume-icons = {
              "on" = " ";
            };
            random-icons = {
              "off" = "<span color=\"#f53c3c\"></span> ";
              "on" = " ";
            };
            repeat-icons = {
              "on" = " ";
            };
            single-icons = {
              "on" = "1 ";
            };
            state-icons = {
              "paused" = "";
              "playing" = "";
            };
            tooltip-format = "MPD (connected)";
            tooltip-format-disconnected = "MPD (disconnected)";
          };
        };
      }];
    };

    # Notification daemon, Mako configuration
    programs.mako = {
      enable = true;
      # default timeout in milliseconds
      defaultTimeout = 5000;
    };

    # Autostart sway in zsh
    programs.zsh.initExtra = ''
      # If running from tty1 start sway
      [[ "$(tty)" == /dev/tty1 ]] && exec sway
    '';

    # This enables discovering fonts that where installed with home.packages
    fonts.fontconfig.enable = true;

    # Empty dummy file to create the folder needed to store screenshots
    home.file."screenshots/.keep".text = "";

    xdg.configFile."sway/scripts".source = ../configs/sway/scripts;
    xdg.configFile."sway/backgrounds".source = ../configs/sway/backgrounds;
    xdg.configFile."waybar/style.css".source = ../configs/waybar/style.css;

    xdg.configFile."wofi".source = ../configs/wofi;
    xdg.configFile."wlogout".source = ../configs/wlogout;
  };
}
