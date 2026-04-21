{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  cfg = osConfig.custom.hm.modules.hyprland;
  enable = osConfig.custom.gui.hyprland;
  desktop = cfg.laptopDisplay == null;

  # Convert monitor list to Hyprland monitor strings
  monitorStrings =
    if cfg.monitors == [ ] then
      [ ".,preferred,auto,1" ]
    else
      map (
        m:
        "${m.name},${if m.resolution == null then "preferred" else m.resolution},${
          if m.position == null then "auto" else m.position
        },${toString m.scale}"
      ) cfg.monitors;

  # Startup programs — same pattern as sway.nix
  startupPrograms =
    [
      {
        command = "${pkgs.thunderbird}/bin/thunderbird --disable-log";
        always = false;
        serviceName = "startup-thunderbird";
      }
      {
        command = "${pkgs.keepassxc}/bin/keepassxc";
        always = false;
        serviceName = "startup-keepassxc";
        env = [
          "PATH=${config.home.profileDirectory}/bin"
        ];
      }
      {
        command = "${pkgs.blueman}/bin/blueman-applet";
        always = false;
        serviceName = "startup-blueman-applet";
      }
      {
        command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        always = false;
        serviceName = "polkit-gnome-authentication-agent";
      }
    ]
    ++ lib.optionals osConfig.custom.networking.wifiSupport [
      {
        command = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        always = false;
        serviceName = "startup-nm-applet";
      }
    ];

  createStartupServices =
    progs:
    builtins.listToAttrs (
      map (p: {
        name = p.serviceName;
        value = {
          Unit = {
            Requires = [ "tray.target" ];
            After = [
              "graphical-session.target"
              "tray.target"
            ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = p.command;
          }
          // (lib.optionalAttrs ((p.precommand or "") != "") {
            ExecStartPre = p.precommand;
          })
          // (lib.optionalAttrs ((builtins.length (p.env or [ ])) != 0) {
            Environment = p.env;
          });
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      }) progs
    );

  # Workspace switching/moving bindings (1-10 on main, F1-F10 on secondary)
  wsBinds =
    (map (n: "SUPER, ${toString n}, workspace, ${toString n}") (lib.range 1 9))
    ++ [ "SUPER, 0, workspace, 10" ]
    ++ (map (n: "SUPER SHIFT, ${toString n}, movetoworkspace, ${toString n}") (lib.range 1 9))
    ++ [ "SUPER SHIFT, 0, movetoworkspace, 10" ]
    ++ (map (n: "SUPER, F${toString n}, workspace, ${toString (10 + n)}") (lib.range 1 10))
    ++ (map (n: "SUPER SHIFT, F${toString n}, movetoworkspace, ${toString (10 + n)}") (lib.range 1 10));

  # Move workspace to current monitor
  wsMoveBinds =
    (map (n: "SUPER CTRL, ${toString n}, moveworkspacetomonitor, ${toString n} current") (lib.range 1 9))
    ++ [ "SUPER CTRL, 0, moveworkspacetomonitor, 10 current" ];

in
{
  config = lib.mkIf enable {

    home.packages = with pkgs; [
      agsv1
      hyprlock
      hypridle
      qt5.qtwayland
      xlsclients
      xhost
      wl-clipboard
      wdisplays
      grim
      slurp
    ];

    # Deploy AGS config (symlink to the Nix store copy)
    xdg.configFile."ags".source = ../configs/ags;

    # Screenshots directory
    home.file."screenshots/.keep".text = "";

    # Hyprlock config
    xdg.configFile."hypr/hyprlock.conf".text = ''
      background {
        monitor =
        path = screenshot
        blur_passes = 3
        blur_size = 7
        brightness = 0.5
      }

      input-field {
        monitor =
        size = 300, 50
        outline_thickness = 2
        dots_size = 0.33
        dots_spacing = 0.15
        outer_color = rgb(4C566A)
        inner_color = rgb(3B4252)
        font_color = rgb(D8DEE9)
        position = 0, -100
        halign = center
        valign = center
      }

      label {
        monitor =
        text = cmd[update:1000] echo $(date +"%H:%M")
        font_size = 72
        position = 0, 100
        halign = center
        valign = center
        color = rgb(D8DEE9)
      }
    '';

    # Idle management
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          before_sleep_cmd = "${pkgs.hyprlock}/bin/hyprlock";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "${pkgs.hyprlock}/bin/hyprlock";
          }
          {
            timeout = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;

      settings = {
        monitor = monitorStrings;

        general = {
          gaps_in = 9;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgb(5E81AC)";
          "col.inactive_border" = "rgb(4C566A)";
          layout = "dwindle";
        };

        decoration = {
          rounding = 9;
          blur = {
            enabled = true;
            size = 5;
            passes = 2;
          };
          shadow = {
            enabled = true;
          };
        };

        animations = {
          enabled = true;
          bezier = "overshot,0.05,0.9,0.1,1.1";
          animation = [
            "windows,1,7,overshot,slide"
            "workspaces,1,7,overshot,slide"
            "fade,1,7,default"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        misc = {
          disable_hyprland_logo = true;
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
        };

        input = {
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            tap-to-click = true;
            disable_while_typing = true;
          };
        };

        "exec-once" = [
          "${pkgs.agsv1}/bin/ags"
          # Restart portal services to ensure correct environment
          "systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland; systemctl --user start xdg-desktop-portal xdg-desktop-portal-hyprland"
        ];

        bind =
          [
            # Lock / session
            "SUPER ALT, L, exec, ${pkgs.hyprlock}/bin/hyprlock"
            # Launcher and terminal
            "SUPER, D, exec, ${pkgs.agsv1}/bin/ags -t applauncher"
            "SUPER, Return, exec, ${pkgs.alacritty}/bin/alacritty"
            # Notifications / quicksettings
            "SUPER SHIFT, N, exec, ${pkgs.agsv1}/bin/ags -t quicksettings"
            # Window management
            "SUPER SHIFT, Q, killactive,"
            "SUPER SHIFT, Space, togglefloating,"
            "SUPER, F, fullscreen,"
            # Tiling splits (dwindle)
            "SUPER, B, layoutmsg, preselect r"
            "SUPER, V, layoutmsg, preselect d"
            "SUPER, E, togglesplit,"
            # Screenshots
            ", Print, exec, ${pkgs.grim}/bin/grim ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png"
            "SUPER, Print, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png"
            # Focus
            "SUPER, left, movefocus, l"
            "SUPER, right, movefocus, r"
            "SUPER, up, movefocus, u"
            "SUPER, down, movefocus, d"
            # Move windows
            "SUPER SHIFT, left, movewindow, l"
            "SUPER SHIFT, right, movewindow, r"
            "SUPER SHIFT, up, movewindow, u"
            "SUPER SHIFT, down, movewindow, d"
          ]
          ++ wsBinds
          ++ wsMoveBinds;

        binde =
          [
            ", XF86AudioRaiseVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +1%"
            ", XF86AudioLowerVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -1%"
          ]
          ++ lib.optionals (!desktop) [
            ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set +2%"
            ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 2%-"
          ];

        bindl =
          [
            ", XF86AudioMute, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"
            ", XF86AudioMicMute, exec, ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle"
          ]
          ++ lib.optionals (!desktop) [
            ", switch:on:Lid Switch, exec, hyprctl keyword monitor ${cfg.laptopDisplay},disable"
            ", switch:off:Lid Switch, exec, hyprctl keyword monitor ${cfg.laptopDisplay},preferred,auto,1"
          ];

        windowrulev2 = [
          "float, class:^pavucontrol$"
          "float, title:^Print$"
          "float, class:^firefox$, title:^Firefox — Sharing Indicator$"
          "float, class:^xdg-desktop-portal-gtk$"
          "float, class:^org.keepassxc.KeePassXC$, title:^KeePassXC - Browser Access Request$"
          "float, title:^Steam - News, class:^Steam$"
          "float, title:^Friends List$, class:^Steam$"
          # Zoom
          "float, title:^.zoom$"
          "float, title:^zoom$"
          "float, title:^Settings$, class:^zoom$"
          "float, title:^Polls$, class:^zoom$"
          "float, title:^as_toolbar$, class:^zoom$"
          "float, title:^Select a window.*$, class:^zoom$"
          # Workspace assignments
          "workspace 18 silent, class:^thunderbird$"
          "workspace 20 silent, class:^org.keepassxc.KeePassXC$, title:^(?!KeePassXC - Browser Access Request)(?!Unlock Database - KeePassXC)"
        ];
      };

      extraConfig =
        ''
          # Present submap (mirrors Sway's present mode, bound to SUPER+P)
          bind = SUPER, P, submap, present
          submap = present
          bind = , m, exec, ${pkgs.wl-mirror}/bin/wl-present mirror
          bind = , m, submap, reset
          bind = , o, exec, ${pkgs.wl-mirror}/bin/wl-present set-output
          bind = , o, submap, reset
          bind = , r, exec, ${pkgs.wl-mirror}/bin/wl-present set-region
          bind = , r, submap, reset
          bind = SHIFT, r, exec, ${pkgs.wl-mirror}/bin/wl-present unset-region
          bind = SHIFT, r, submap, reset
          bind = , s, exec, ${pkgs.wl-mirror}/bin/wl-present set-scaling
          bind = , s, submap, reset
          bind = , f, exec, ${pkgs.wl-mirror}/bin/wl-present toggle-freeze
          bind = , f, submap, reset
          bind = , c, exec, ${pkgs.wl-mirror}/bin/wl-present custom
          bind = , c, submap, reset
          bind = , Return, submap, reset
          bind = , Escape, submap, reset
          submap = reset
        ''
        + lib.optionalString (cfg.extraConfig != null) cfg.extraConfig;
    };

    # Startup services
    systemd.user.services = createStartupServices startupPrograms;

    # Clipboard manager
    services.copyq.enable = true;
  };
}
