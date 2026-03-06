{ config, pkgs, lib, osConfig, ... }:

let
  cfg = osConfig.custom.hm.modules;

  laptopDisplay = cfg.sway.laptopDisplay;

  hwmonPath = cfg.waybar.hwmonPath; # sys-fs path, i.e. "/sys/class/hwmon/hwmon0/temp1_input"
  thermalZone = cfg.waybar.thermalZone; # Integer value

  gpuCfg = cfg.waybar.gpu;
  # First we create a list of the setting values
  # After that we remove the null elements and get the count of the remaining values
  gpuCfgValueCount = builtins.length (builtins.filter (x: x != null) (builtins.attrValues gpuCfg));
  # We enable gpu stats iff at least gpu stat command was given
  enableGpuStats = gpuCfgValueCount > 0;

  hmManageSway = osConfig.custom.gui == "hm-wayland";
  enable = hmManageSway || (osConfig.custom.gui == "wayland");

  # Waybar settings
  enableSystemdWaybar = config.wayland.windowManager.sway.enable && config.wayland.windowManager.sway.systemd.enable;
  waybarLaptopFeatures = laptopDisplay != null;
in {
  config = let
    waybarPkg = (pkgs.waybar.override { withMediaPlayer = true; });
  in lib.mkIf enable {
    # systemd.user.services.waybar.Unit.After = [ "graphical-session.target" "bluetooth.target" ];
    systemd.user.services.waybar.Unit.After = [ "bluetooth.target" ];

    # Waybar configuration
    programs.waybar = {
      enable = true;
      systemd = {
        enable = enableSystemdWaybar;
        target = "sway-session.target";
      };
      package = waybarPkg;

      settings = [{
        modules-left = [
          "sway/workspaces"
          "custom/scratchpad-indicator"
          "sway/mode"
        ] ++
        lib.optionals osConfig.custom.bluetooth [
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
          "custom/notification"
          "temperature"
          "cpu"
          "memory"
        ] ++ lib.optionals enableGpuStats [
          "custom/gpu"
        ] ++ [
          "custom/disk_root"
          "group/audio-out"
          "group/audio-in"
        ] ++ lib.optionals waybarLaptopFeatures [
          "group/backlight"
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
            format = "🏠{}";
            interval = 180;
            exec = "${pkgs.coreutils}/bin/df -h --output=avail $HOME | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.coreutils}/bin/tr -d ' '";
            tooltip = false;
            escape = true;
          };
          "custom/disk_root" = {
            format = "💽{}";
            interval = 180;
            exec = "${pkgs.coreutils}/bin/df -h --output=avail / | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.coreutils}/bin/tr -d ' '";
            tooltip = false;
            escape = true;
          };
          "custom/logout" = {
            justify = "center";
            format = "";
            on-click = "${pkgs.wlogout}/bin/wlogout";
            on-click-right = "${pkgs.wlogout}/bin/wlogout";
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
              "exec" = "${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq --unbuffered --compact-output '( select(.name == \"root\") | .nodes[] | select(.name == \"__i3\") | .nodes[] | select(.name == \"__i3_scratch\") | .focus) as $scratch_ids | [..  | (.nodes? + .floating_nodes?) // empty | .[] | select(.id |IN($scratch_ids[]))] as $scratch_nodes | { text: \"\\($scratch_nodes | length)\", tooltip: $scratch_nodes | map(\"\\(.app_id // .window_properties.class) (\\(.id)): \\(.name)\") | join(\"\\n\") }'";
              # "format" = "􏠜 {}";
              "format" = "{}";
              "on-click" = "exec ${pkgs.sway}/bin/swaymsg 'scratchpad show'";
              "on-click-right" = "exec ${pkgs.sway}/bin/swaymsg 'move scratchpad'";
              escape = true;
          };
          "temperature" = {
            critical-threshold = 90;
            # format-critical = "{temperatureC:>3}°C {icon}";
            format = "{icon} {temperatureC}°C";
            format-icons = [
              "<span color='#0c6e08'></span>" # Icon: temperature-empty
              "<span color='#adca39'></span>" # Icon: temperature-quarter
              "<span color='#e88939'></span>" # Icon: temperature-half
              "<span color='#e85f39'></span>" # Icon: temperature-three-quarters
              "<span color='#ff3700'></span>" # Icon: temperature-full
            ];
            tooltip = false;
          } // (if (hwmonPath != null) then { hwmon-path = hwmonPath; } else {})
            // (if (thermalZone != null) then { thermal-zone = thermalZone; } else {});
          "cpu" = {
            format = "{usage:>3}%";
            tooltip = false;
            on-click = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
            on-click-right = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
          };
          "memory" = {
            format = " {used:0.1f}G";
            on-click = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
            on-click-right = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
          };
          "custom/notification" = {
            justify = "center";
            tooltip = false;
            format = "{icon}";
            format-icons = {
              "notification" = "<span font='10'></span><span foreground='red'><sup></sup></span>";
              "none" = "<span font='10'></span>";
              "dnd-notification" = "<span font='10'></span><span foreground='red'><sup></sup></span>";
              "dnd-none" = "<span font='10'></span>";
            };
            "return-type" = "json";
            "exec" = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
            "on-click" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
            "on-click-right" = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
            "escape" = true;
          };
          "bluetooth" = {
              justify = "center";
              interval = 30;
              format-on = "<span color='#589df6'></span>";
              format-off = "";
              format-disabled = "";
              format-connected = "<span color='#589df6'></span> {device_alias}";
              # format-connected-battery = "<span color='#589df6'></span> {device_alias} {device_battery_percentage}%";
              format-connected-battery = "<span color='#589df6'></span> {device_alias}{icon}";
              tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
              tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
              # Bluetooth battery status icons from low to high
              format-icons = ["" "" "" "" ""];
              #format-icons = ["" "" "" "" ""];
              on-click = "${pkgs.blueman}/bin/blueman-manager";
              on-click-right = "${pkgs.util-linux}/bin/rfkill toggle bluetooth";
          };
          "network" = {
            family = "ipv4";
            format-wifi = "<span color='#589df6'></span> <span color='gray'>{essid}</span> <span color='#589df6'>{signalStrength}%</span> <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-ethernet = " {ifname}: {ipaddr} <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-linked = " {ifname} (No IP) <span color='#589df6'>⇵</span> {bandwidthDownBits}|{bandwidthUpBits}";
            format-disconnected = "⚠ Disconnected";
            interval = 2;
            on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
            on-click-right = "${pkgs.util-linux}/bin/rfkill toggle wlan";
            tooltip = false;
          };
          "group/backlight" = {
            "orientation" = "inherit";
            "drawer" = {
              "transition-duration" = 300;
              "children-class" = "backlight-drawer-child";
              "transition-left-to-right" = false;
            };
            "modules" = [
              "backlight"
              "backlight/slider"
            ];
          };
          "backlight/slider" = {
              "min" = 0;
              "max" = 100;
              "orientation" = "horizontal";
              "device" = "intel_backlight";
          };
          "backlight" = {
            device = "intel_backlight";
            format = "{icon} {percent:>3}%";
            format-icons = ["🔅" "🔆"];
            tooltip = false;
          };
          "pulseaudio#out" = {
            # scroll-step = 1; # %, can be a float
            format = "{icon}{volume:>3}%";
            format-muted = "🔇  0%";
            format-bluetooth = "{icon}{volume:>3}%";
            format-bluetooth-muted = "🔇  0%";

            format-source = "";
            format-source-muted = "";

            format-icons = {
              "headphone" = "";
              "hands-free" = "";
              "headset" = "";
              "phone" = "";
              "portable" = "";
              "car" = "";
              "default" = ["🔈" "🔉" "🔊"];
            };
            ignored-sinks = [ "Easy Effects Sink" ];
            on-click = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            tooltip = false;
          };
          "pulseaudio#in" = {
            format = "{format_source}";
            format-muted = "{format_source}";
            format-bluetooth = "{format_source}";
            format-bluetooth-muted = "{format_source}";

            format-source = "{volume:>3}%";
            format-source-muted = "  0%";

            target = "source";
            on-click = "${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            tooltip = false;
          };
          "group/audio-out" = {
            "orientation" = "inherit";
            "drawer" = {
              "transition-duration" = 300;
              "children-class" = "audio-drawer-child";
              "transition-left-to-right" = false;
            };
            "modules" = [
              "pulseaudio#out"
              "pulseaudio/slider#out"
            ];
          };
          "group/audio-in" = {
            "orientation" = "inherit";
            "drawer" = {
              "transition-duration" = 300;
              "children-class" = "audio-drawer-child";
              "transition-left-to-right" = false;
            };
            "modules" = [
              "pulseaudio#in"
              "pulseaudio/slider#in"
            ];
          };
          "pulseaudio/slider#out" = {
            "min" = 0;
            "max" = 100;
            "rotate" = 0;
            "scroll-step" = 1;
          };
          "pulseaudio/slider#in" = {
            "min" = 0;
            "max" = 100;
            "rotate" = 0;
            "scroll-step" = 1;
            "target" = "source";
          };
          "clock" = {
            interval = 60;
            timezone = "Europe/Berlin";
            format = "{:%H:%M|%e %b}";
            tooltip-format = "{:%H:%M | %d-%m-%Y}";
            on-click = "${pkgs.gnome-calendar}/bin/gnome-calendar";
          };
          "battery" = {
            states = {
              "good" = 80;
              "warning" = 20;
              "critical" = 10;
            };
            format = "{icon}{capacity:>3}%{time}";
            format-time = " {H}h{M}m";
            format-charging = "{icon}<span color='#e88939'></span>{capacity:>3}%{time}";
            # format-charging = "{icon}<span color='#e88939'></span>{capacity:>3}%{time}";
            format-plugged =  "{icon}<span color='#e88939'></span>{capacity:>3}%{time}";
            # format-good = "", # An empty format will hide the module
            # format-full = "";
            # format-icons = [
            #   "<span font='8.6' rise='-500'></span>"
            #   "<span font='8.6' rise='-500'></span>"
            #   "<span font='8.6' rise='-500'></span>"
            #   "<span font='8.6' rise='-500'></span>"
            #   "<span font='8.6' rise='-500'></span>"
            # ];
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };
          "idle_inhibitor" = {
            justify = "center";
            format = "<span font='8' color='#589df6'>{icon}</span>";
            format-icons = {
              "activated" = "";
              "deactivated" = "";
            };
          };
          "tray" = {
            # icon-size = 21;
            spacing = 5;
          };
          "custom/spotify" = {
            format = "{icon}:{}";
            return-type = "json";
            max-length = 40;
            format-icons = {
              "spotify" = "";
              "firefox" = "";
              "default" = "🎜";
            };
            escape = true;
            # Filter player based on name
            exec = "${waybarPkg}/bin/waybar-mediaplayer.py --player spotify 2> /dev/null"; # Script in resources folder
            exec-if = "${pkgs.procps}/bin/pgrep spotify";
            on-click = "${pkgs.playerctl}/bin/playerctl -p spotify play-pause";
            on-click-right = "${pkgs.playerctl}/bin/playerctl -p spotify next";
          };
          "custom/media_firefox" = {
            format = "{icon}:{}";
            return-type = "json";
            max-length = 40;
            format-icons = {
              "spotify" = "";
              "firefox" = "";
              "default" = "🎜";
            };
            escape = true;
            # Filter player based on name
            exec = "${waybarPkg}/bin/waybar-mediaplayer.py --player firefox 2> /dev/null"; # Script in resources folder
            exec-if = "${pkgs.procps}/bin/pgrep 'Web Content'";
            on-click = "${pkgs.playerctl}/bin/playerctl -p firefox play-pause";
            on-click-right = "${pkgs.playerctl}/bin/playerctl -p firefox next";
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

      style = ''
        /* Based on: https://github.com/Pipshag/dotfiles_nord/blob/master/.config/waybar/style.css */

        /* COLORS */

        /* Nord */
        @define-color nord_bg #434C5E;
        @define-color nord_bg_blue #546484;
        @define-color nord_light #D8DEE9;
        @define-color nord_light_font @nord_light;
        @define-color nord_dark_font @nord_bg;
        @define-color bg #2E3440;
        /*@define-color bg #353C4A;*/
        /*@define-color dark @nord_dark_font;*/

        @define-color waybar_bg @bg;
        @define-color waybar_color @nord_light_font;

        @define-color warning #ebcb8b;
        @define-color warning_color @nord_dark_font;
        @define-color critical #BF616A;
        @define-color critical_color @nord_dark_font;

        /* Module Colors: */

        /* Left */
        /*@define-color workspaces @bg;*/
        /*@define-color workspaces @nord_dark_font;*/
        /*@define-color workspacesfocused @nord_bg;*/
        @define-color workspacesfocused #4C566A;
        @define-color workspacesfocused_color @nord_light_font;

        @define-color scratchpad @nord_light;
        @define-color scratchpad_color @nord_dark_font;

        @define-color mode @nord_bg;
        @define-color mode_color @nord_light_font;

        @define-color bluetooth @nord_bg;

        @define-color network @nord_bg;
        @define-color network_color @nord_light_font;

        /* Center */
        @define-color tray @nord_bg;

        /* Right */
        @define-color temp @nord_bg;
        @define-color temp_color @nord_light_font;

        @define-color cpu @nord_bg;
        @define-color cpu_color @nord_light_font;

        @define-color memory @nord_bg;
        @define-color memory_color @nord_light_font;

        @define-color audio @nord_bg_blue;
        @define-color audio_color @nord_light_font;

        @define-color backlight @nord_bg;
        @define-color backlight_color @nord_light_font;

        @define-color battery @nord_bg;
        @define-color battery_color @nord_light_font;

        @define-color clock @nord_bg_blue;
        @define-color clock_color @nord_light_font;
        @define-color date @nord_bg;
        @define-color time @nord_bg;

        @define-color idle @nord_bg;

        @define-color custom_bg @nord_bg;
        @define-color custom_color @nord_light_font;

        @define-color language @nord_bg_blue;
        @define-color language_color @nord_light_font;


        * {
            /* fck default gtk-theme settings! */
            all: unset;
            /* all: initial; */

            border: none;
            border-radius: 2px;
            font-family: "MesloLGS Nerd Font", monospace;
            font-size: 10px;
            /* min-height: 0; */
            /* min-width: 0; */
            margin: 1px 0.2em 1px 0.2em;

            /* min-height: 14px; */
        }

        window#waybar {
            background-color: @waybar_bg;
            color: @waybar_color;
            font-weight: bold;
        }

        tooltip {
            background: rgba(43, 48, 59, 0.7);
            border: 1px solid rgba(100, 114, 125, 0.7);
        }

        tooltip label {
            color: white;
        }

        /* Workspaces stuff */

        #workspaces button {
            padding: 0 2px;
            margin: 0px;
            opacity: 0.3;
            background: none;
            color: #ff8700;
            border: 1px solid #1b1d1e;
        }

        #workspaces button.focused {
            background-color: @workspacesfocused;
            color: @workspacesfocused_color;
            opacity: 1;
            padding: 0 0.2em;
        }

        #workspaces button.urgent {
            border-color: #c9545d;
            color: #c9545d;
            opacity: 1;
        }

        #window {
            margin-right: 40px;
            margin-left: 40px;
            font-weight: normal;
        }

        /* Each module */
        #custom-gpu,
        #custom-disk_home,
        #custom-disk_root,
        #custom-notification,
        #custom-logout,
        #custom-spotify,
        #custom-media_firefox,
        #bluetooth,
        #temperature,
        #clock,
        #battery,
        #cpu,
        #memory,
        #network,
        #pulseaudio,
        #pulseaudio-slider,
        #backlight-slider,
        #backlight,
        #idle_inhibitor,
        #tray,
        #mode,
        #mpd {
            padding-left: 0.2em;
            padding-right: 0.2em;
        }

        /* Each module that should blink */
        #mode,
        #memory,
        #temperature,
        #battery {
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }

        /* Each critical module */
        #memory.critical,
        #cpu.critical,
        #temperature.critical,
        #battery.critical {
            background-color: @critical;
            color: @critical_color;
        }

        /* Each critical that should blink */
        #mode,
        #memory.critical,
        #temperature.critical,
        #battery.critical.discharging {
            animation-name: blink-critical;
            animation-duration: 2s;
        }

        /* Each warning */
        #network.disconnected,
        #memory.warning,
        #cpu.warning,
        #temperature.warning,
        #battery.warning {
            background-color: @warning;
            color: @warning_color;
        }

        /* Each warning that should blink */
        #battery.warning.discharging {
            animation-name: blink-warning;
            animation-duration: 3s;
        }

        #mode {
            /* Shown current Sway mode (resize etc.) */
            background-color: @mode;
            color: @mode_color;
        }

        #bluetooth {
            background-color: @bluetooth;
            /* font-size: 1.2em; */
            padding: 0 0.2em;
        }

        #custom-gpu,
        #custom-disk_home,
        #custom-disk_root,
        #custom-notification,
        #custom-logout,
        #custom-spotify {
            background-color: @custom_bg;
            color: @custom_color;
            padding: 0 0.2em;
        }

        #idle_inhibitor {
            min-width: 10px;
        }
        #custom-notification {
            min-width: 15px;
            /* padding-right: 7px; */
        }
        #custom-logout {
            min-width: 15px;
            /* padding-right: 4px; */
            margin-right: 0em;
        }

        #custom-scratchpad-indicator {
            background-color: @scratchpad;
            color: @scratchpad_color;
            padding: 0 0.2em;
        }

        #idle_inhibitor {
            background-color: @idle;
            padding: 0 0.2em;
            padding-right: 7px;
            /*margin-right: 0.1em; */
        }

        #network {
            background-color: @network;
            color: @network_color;
        }

        #memory {
            background-color: @memory;
            color: @memory_color;
        }

        #cpu {
            background-color: @cpu;
            color: @cpu_color;
        }

        #language {
            background-color: @language;
            color: @language_color;
            padding: 0 0.2em;
        }

        #temperature {
            background-color: @temp;
            color: @temp_color;
        }

        #battery {
            background-color: @battery;
            color: @battery_color;
        }

        #backlight {
            background-color: @backlight;
            color: @backlight_color;
        }

        #clock {
            background-color: @clock;
            color: @clock_color;
        }

        #clock.date {
            background-color: @date;
        }

        #clock.time {
            background-color: @time;
        }

        #pulseaudio.in,
        #pulseaudio.out {
            background-color: @audio;
            color: @audio_color;
        }

        #pulseaudio.out.muted,
        #pulseaudio.in.source-muted {
            background-color: #D08770;
            color: @audio_color;
            /* No styles */
        }

        #backlight-slider,
        #pulseaudio-slider {
            padding: 0;
            margin: 0;
            /* background-color: @audio; */
        }
        #backlight-slider slider,
        #pulseaudio-slider slider {
            min-height: 0px;
            min-width: 0px;
            opacity: 0;
            background-image: none;
            border: none;
            box-shadow: none;
        }
        #backlight-slider trough,
        #pulseaudio-slider trough {
            min-height: 10px;
            min-width: 80px;
            border-radius: 5px;
            background: black;
        }
        #backlight-slider highlight,
        #pulseaudio-slider highlight {
            min-width: 10px;
            border-radius: 5px;
            background: green;
        }

        #tray {
            background-color: @tray;
        }

        #tray menu {
            background: rgba(43, 48, 59, 0.7);
            border: 1px solid rgba(100, 114, 125, 0.7);
        }
      '';
    };

    # This enables discovering fonts that where installed with home.packages
    fonts.fontconfig.enable = true;

    xdg.configFile."waybar/scripts/custom_gpu.sh" = {
      text = ''
        #!/bin/sh
      '' + (lib.optionalString (gpuCfg.mhzFreqCmd != null) ''
        raw_clock=$(${gpuCfg.mhzFreqCmd})
        clock=$(echo "scale=1;$raw_clock/1000" | ${pkgs.bc}/bin/bc | ${pkgs.gnused}/bin/sed -e 's/^-\./-0./' -e 's/^\./0./')
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

    xdg.configFile."wlogout/layout".text = let 
      layout = [
        {
          "label" = "lock";
          "action" = "${pkgs.swaylock-effects}/bin/swaylock";
          "text" = "Lock";
          "keybind" = "l";
        }
        {
          "label" = "hibernate";
          "action" = "${pkgs.systemd}/bin/systemctl hibernate";
          "text" = "Hibernate";
          "keybind" = "h";
        }
        {
          "label" = "logout";
          # "action" = "${pkgs.systemd}/bin/loginctl terminate-user $USER";
          "action" = "${pkgs.sway}/bin/swaymsg exit";
          "text" = "Logout";
          "keybind" = "e";
        }
        {
          "label" = "shutdown";
          "action" = "${pkgs.systemd}/bin/systemctl poweroff";
          "text" = "Shutdown";
          "keybind" = "s";
        }
        {
          "label" = "suspend";
          "action" = "${pkgs.systemd}/bin/systemctl suspend";
          "text" = "Suspend";
          "keybind" = "u";
        }
        {
          "label" = "reboot";
          "action" = "${pkgs.systemd}/bin/systemctl reboot";
          "text" = "Reboot";
          "keybind" = "r";
        }
      ];

      layoutToJSON = ll: builtins.concatStringsSep "\n" (builtins.map (l: builtins.toJSON l) ll);
    in layoutToJSON layout;
  };
}
