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

    home.packages = with pkgs; [
      # needed for waybar customization
      font-awesome
    ];

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
            on-click = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
            on-click-right = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
          };
          "memory" = {
            format = " {used:0.1f}G";
            on-click = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
            on-click-right = "${pkgs.alacritty}/bin/alacritty --command ${pkgs.htop}/bin/htop";
          };
          "custom/notification" = {
            "tooltip" = false;
            "format" = "{icon}";
            "format-icons" = {
              "notification" = "<span foreground='red'><sup></sup></span>";
              "none" = "";
              "dnd-notification" = "<span foreground='red'><sup></sup></span>";
              "dnd-none" = "";
            };
            "return-type" = "json";
            "exec" = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
            "on-click" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
            "on-click-right" = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
            "escape" = true;
          };
          "bluetooth" = {
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
          "backlight" = {
            device = "intel_backlight";
            format = "{icon} {percent}%";
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

            on-click = "${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";

            on-scroll-up = "${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ +1%";
            on-scroll-down = "${pkgs.pulseaudio}/bin/pactl set-source-volume @DEFAULT_SOURCE@ -1%";
            tooltip = false;
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
            format-icons = [
              "<span font='8.6' rise='-500'></span>"
              "<span font='8.6' rise='-500'></span>"
              "<span font='8.6' rise='-500'></span>"
              "<span font='8.6' rise='-500'></span>"
              "<span font='8.6' rise='-500'></span>"
            ];
          };
          "idle_inhibitor" = {
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
    };

    # This enables discovering fonts that where installed with home.packages
    fonts.fontconfig.enable = true;

    xdg.configFile."waybar/style.css".source = ../configs/waybar/style.css;
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
          "action" = "${pkgs.systemd}/bin/loginctl terminate-user $USER";
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
