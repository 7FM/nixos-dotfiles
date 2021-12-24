{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hm.modules;

  laptopDisplay = cfg.sway.laptopDisplay;

  hwmonPath = cfg.waybar.hwmonPath; # sys-fs path, i.e. "/sys/class/hwmon/hwmon0/temp1_input"
  thermalZone = cfg.waybar.thermalZone; # Integer value

  gpuCfg = cfg.waybar.gpu;
  # First we create a list of the setting values
  # After that we remove the null elements and get the count of the remaining values
  gpuCfgValueCount = builtins.length (builtins.filter (x: x != null) (builtins.attrValues gpuCfg));
  # We enable gpu stats iff at least gpu stat command was given
  enableGpuStats = gpuCfgValueCount > 0;

  hmManageSway = config.custom.gui == "hm-wayland";
  enable = hmManageSway || (config.custom.gui == "wayland");

  # Waybar settings
  enableSystemdWaybar = false;
  waybarLaptopFeatures = laptopDisplay != null;
in {
  options.custom.hm.modules = with lib; {
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
            I.e. "cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input"
          '';
        };
        mhzFreqCmd = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The command to use to determine the gpu clock frequency in MHz.
            I.e. "cat /sys/class/drm/card0/device/pp_dpm_sclk | egrep -o '[0-9]{0,4}Mhz \\W' | sed 's/Mhz \\*//'"
            or   "cat /sys/class/drm/card0/gt_cur_freq_mhz"
          '';
        };
        usageCmd = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The command to use to determine the gpu usage in percent.
            I.e. "cat /sys/class/drm/card0/device/gpu_busy_percent"
          '';
        };
      };
    };
  };

  config = lib.mkIf enable {

    home.packages = with pkgs; [
      # needed for waybar customization
      font-awesome

      gnome.gnome-calendar
      pavucontrol # GUI to control pulseaudio settings
      wlogout # logout menu
      networkmanagerapplet # NetworkManager Front-End
      wpa_supplicant_gui # wpasupplicant Front-End

      bc # needed for gpu clock speed calculation
    ] ++ lib.optionals waybarLaptopFeatures [ 
      brightnessctl
    ];

    # Waybar configuration
    programs.waybar = {
      enable = true;
      systemd.enable = enableSystemdWaybar;
      package = (pkgs.waybar.override { withMediaPlayer = true; });

      settings = [{
        modules-left = [
          "sway/workspaces"
          "custom/scratchpad-indicator"
          "sway/mode"
        ] ++
        lib.optionals config.custom.bluetooth [
          "bluetooth"
        ] ++ [
          "network"
        ];
        modules-center = [
          "tray"
          "custom/spotify"
          "custom/media_firefox"
        ];
        modules-right = [
          "custom/mail"
          "temperature"
          "cpu"
          "memory"
        ] ++ lib.optionals enableGpuStats [
          "custom/gpu"
        ] ++ [
          #"custom/disk_home"
          "custom/disk_root"
          "pulseaudio#out"
          "pulseaudio#in"
        ] ++ lib.optionals waybarLaptopFeatures [ 
          "backlight"
          "battery"
        ] ++ [
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
            escape = true;
          };
          "custom/disk_root" = {
            format = "💽 {}";
            interval = 180;
            exec = "df -h --output=avail / | tail -1 | tr -d ' '";
            tooltip = false;
            escape = true;
          };
          "custom/logout" = {
            format = "";
            on-click = "wlogout";
            on-click-right = "wlogout";
            tooltip = false;
          };
          "custom/gpu" = {
            "exec" = "\${XDG_CONFIG_HOME:-\$HOME/.config}/waybar/scripts/custom_gpu.sh";
            "return-type" = "json";
            "format" = "{}";
            "interval" = 5;
            "tooltip" = "{tooltip}";
            escape = true;
          };
          "custom/scratchpad-indicator" = {
              "interval" = 3;
              "return-type" = "json";
              "exec" = "swaymsg -t get_tree | jq --unbuffered --compact-output '( select(.name == \"root\") | .nodes[] | select(.name == \"__i3\") | .nodes[] | select(.name == \"__i3_scratch\") | .focus) as $scratch_ids | [..  | (.nodes? + .floating_nodes?) // empty | .[] | select(.id |IN($scratch_ids[]))] as $scratch_nodes | { text: \"\\($scratch_nodes | length)\", tooltip: $scratch_nodes | map(\"\\(.app_id // .window_properties.class) (\\(.id)): \\(.name)\") | join(\"\\n\") }'";
              # "format" = "􏠜 {}";
              "format" = "{}";
              "on-click" = "exec swaymsg 'scratchpad show'";
              "on-click-right" = "exec swaymsg 'move scratchpad'";
              escape = true;
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
            escape = true;
          };
          "bluetooth" = {
              "interval" = 30;
              "format" = "{icon}";
              #"format-alt" = "{status}";
              "format-icons" = {
                  "enabled" = "<span color='#589df6'></span>";
                  "disabled" = "";
              };
              "on-click" = "blueman-manager";
          };
          "network" = {
            family = "ipv4";
            format-wifi = "<span color='#589df6'></span> <span color='gray'>{essid}</span> <span color='#589df6'>{signalStrength}%</span> <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-ethernet = " {ifname}: {ipaddr} <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-linked = " {ifname} (No IP) <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-disconnected = "⚠ Disconnected";
            interval = 2;
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
            format = " {:%H:%M  %e %b}";
            tooltip-format = "{:%d-%m-%Y | %H:%M}";
            on-click = "gnome-calendar";
          };
          "battery" = {
            states = {
              "good" = 80;
              "warning" = 20;
              "critical" = 10;
            };
            format = "{icon}{capacity:>3}%{time}";
            format-time = " {H}h{M}m";
            format-charging = "{icon} <span color='#e88939'></span>{capacity:>3}%{time}";
            format-plugged =  "{icon} <span color='#e88939'></span>{capacity:>3}%{time}";
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

    # This enables discovering fonts that where installed with home.packages
    fonts.fontconfig.enable = true;

    xdg.configFile."waybar/style.css".source = ../configs/waybar/style.css;
    xdg.configFile."waybar/scripts/custom_gpu.sh" = {
      text = ''
        #!/bin/sh
      '' + (lib.optionalString (gpuCfg.mhzFreqCmd != null) ''
        raw_clock=$(${gpuCfg.mhzFreqCmd})
        clock=$(echo "scale=1;$raw_clock/1000" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./')
      '') + (lib.optionalString (gpuCfg.tempCmd != null) ''
        raw_temp=$(${gpuCfg.tempCmd})
        temperature=$(($raw_temp/1000))
      '') + (lib.optionalString (gpuCfg.usageCmd != null) ''
        busypercent=$(${gpuCfg.usageCmd})
      '') + ''
        echo '{"text": "'' +
        (lib.optionalString (gpuCfg.mhzFreqCmd != null) '''$clock'GHz'' + lib.optionalString (gpuCfg.tempCmd != null || gpuCfg.usageCmd != null) " ") +
        (lib.optionalString (gpuCfg.tempCmd != null) '' '$temperature'°C'' + lib.optionalString (gpuCfg.usageCmd != null) " ") +
        (lib.optionalString (gpuCfg.usageCmd != null) '''$busypercent'%'') +
        ''", "class": "custom-gpu", "tooltip": ""}'
      '';
      executable = true;
    };
    xdg.configFile."wofi".source = ../configs/wofi;
    xdg.configFile."wlogout".source = ../configs/wlogout;
  };
}
