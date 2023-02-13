{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hm.modules;

  laptopDisplay = cfg.sway.laptopDisplay;
  disp1 = cfg.sway.disp1;
  disp1_res = cfg.sway.disp1_res;
  disp1_pos = cfg.sway.disp1_pos;
  disp2 = if cfg.sway.disp2 == null then disp1 else cfg.sway.disp2;
  disp2_res = cfg.sway.disp2_res;
  disp2_pos = cfg.sway.disp2_pos;

  startupPrograms = [
    { command = "${pkgs.astroid}/bin/astroid --disable-log"; always = false; serviceName = "startup-astroid"; }
    { command = "${pkgs.mattermost-desktop}/bin/mattermost-desktop --enable-features=UseOzonePlatform --ozone-platform=wayland"; always = false; serviceName = "startup-mattermost"; }
    {
      command = "${pkgs.keepassxc}/bin/keepassxc"; always = false; serviceName = "startup-keepassxc";
      env = [
        # Fix QT systemd integration See: https://github.com/nix-community/home-manager/issues/249
        "PATH=${config.home.profileDirectory}/bin"
      ];
    }
    # TODO probably some timing issue... it almost never starts in tray mode!
    {
      command = "${pkgs.wpa_supplicant_gui}/bin/wpa_gui -t"; always = false; serviceName = "startup-wpa_gui"; 
      env = [
        # Fix QT systemd integration See: https://github.com/nix-community/home-manager/issues/249
        "PATH=${config.home.profileDirectory}/bin"
      ];
    }
    # this one is not installed by homemanager, but the path is identical as we use the same nixpkgs revision
    { command = "${pkgs.blueman}/bin/blueman-applet"; always = false; serviceName = "startup-blueman-applet"; }

    # Authentication agent
    { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; always = false; serviceName = "polkit-gnome-authentication-agent"; }
  ] ++ lib.optionals (!desktop) [
    # Battery level monitor
    { 
      command = "${pkgs.swaynag-battery}/bin/swaynag-battery"; 
      always = false; serviceName = "swaynag-battery";
      env = [
        "PATH=${pkgs.sway}/bin"
      ]; 
    }
  ];

  #lockcmd = "swaylock -f -c 000000";
  lockcmd = "${pkgs.swaylock-effects}/bin/swaylock";
  lockTimeout = 300;
  disableDisplayTimeout = 600;
  disableDisplayCmdRaw = "${pkgs.sway}/bin/swaymsg \"output * dpms off\"";
  disableDisplayCmd = "timeout ${disableDisplayTimeout} '${disableDisplayCmdRaw}'";
  enableDisplayCmdRaw = "${pkgs.sway}/bin/swaymsg \"output * dpms on\"";
  enableDisplayCmd = "resume '${enableDisplayCmdRaw}'";

  enableSystemdSway = true;
  hmManageSway = config.custom.gui == "hm-wayland";
  enable = hmManageSway || (config.custom.gui == "wayland");
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
  };

  config = lib.mkIf enable {

    assertions = [
      {
        assertion = config.custom.hm.modules.sway.disp1 != null;
        message = "If the system is not headless, then at least one display must be defined!";
      }
    ];

    home.packages = lib.optionals hmManageSway (import ../../common/sway_extra_packages.nix { inherit pkgs; });

    wayland.windowManager.sway = (lib.optionalAttrs (!hmManageSway) { package = null; } ) // {
      enable = true;

      wrapperFeatures.gtk = true;
      systemdIntegration = enableSystemdSway;
      extraSessionCommands = import ../../common/sway_extra_session_commands.nix;

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

        menu = "${pkgs.wofi}/bin/wofi --show=drun --lines=5 --prompt=\"\"";

        terminal = "alacritty";

        modifier = mod;

        keybindings = lib.mkOptionDefault ({
          # Volume control
          "XF86AudioRaiseVolume" = "exec \"${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +1%\"";
          "XF86AudioLowerVolume" = "exec \"${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -1%\"";
          "XF86AudioMute" = "exec \"${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle\"";
          "XF86AudioMicMute" = "exec \"${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle\"";
          # Lock hotkey
          "${mod}+${mod2}+l" = "exec ${lockcmd}";
          # Screenshots
          "Print" = "exec ${pkgs.grim}/bin/grim ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png";
          # Take a screenshot of a selected region
          "${mod}+Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png";
          # Toggle the notification control center
          "${mod}+Shift+n" = "exec ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
        } // (lib.optionalAttrs (!desktop) {
          # Brightness control
          "XF86MonBrightnessDown" = "exec \"${pkgs.brightnessctl}/bin/brightnessctl set 2%-\"";
          "XF86MonBrightnessUp" = "exec \"${pkgs.brightnessctl}/bin/brightnessctl set +2%\"";
        }) // createWsKeybindings workspaces);

        startup = [
          # Clipboard manager
          { command = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store"; always = false; }

          # Ensure sway notification center runs
          { command = "${pkgs.swaynotificationcenter}/bin/swaync"; always = false;}

          # Set QT options
          {
            command = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE QT_QPA_PLATFORM QT_WAYLAND_DISABLE_WINDOWDECORATION";
            always = false;
          }

          # Expose the SSH-AGENT
          {
            command = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd SSH_AUTH_SOCK";
            always = false;
          }
        ]
        # Auto-focus the first display
        ++ lib.optional (disp1 != null) { command = "${pkgs.sway}/bin/swaymsg focus output ${disp1}"; always = false; }
        # Clamshell mode
        ++ lib.optional (laptopDisplay != null) { command = "\${XDG_CONFIG_HOME:-\$HOME/.config}/sway/scripts/clamshell_mode_fix.sh ${laptopDisplay}"; always = true; }
        ++ lib.optionals (!enableSystemdSway) ([
          # Import the most important environment variables into the D-Bus and systemd
          # user environments (e.g. required for screen sharing and Pinentry prompts):
          { command = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"; always = false; }

          # Swayidle
          { command = "${pkgs.swayidle}/bin/swayidle -w timeout ${lockTimeout} \"${lockcmd}\" ${disableDisplayCmd} ${enableDisplayCmd} before-sleep \"${lockcmd}\""; always = false; }
          # start usually used programs
        ] ++ startupPrograms);

        assigns = let
          astroidCond = [ { app_id = "^astroid$"; } ];
          mattermostCond1 = [ { class = "^Mattermost$"; } ];
          mattermostCond2 = [ { title = "^Mattermost Desktop App$"; } ];
          keepassCond = [ { app_id = "^org.keepassxc.KeePassXC$"; title = "^(?!KeePassXC - Browser Access Request$)(?!Unlock Database - KeePassXC$)"; } ];
        in lib.optionalAttrs (disp1 != disp2) {
          "18:A8" = astroidCond;
          "19:A9" = mattermostCond1 ++ mattermostCond2;
          "20:A10" = keepassCond;
        } // lib.optionalAttrs (disp1 == disp2) {
          "8" = astroidCond;
          "9" = mattermostCond1 ++ mattermostCond2;
          "10" = keepassCond;
        };

        bars = lib.optionals (!enableSystemdSway) [
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
        output = let 
          createDispCfg = disp: res: pos: {
            "${disp}" = lib.mkIf (res != null) {
              "res" = res;
            } // lib.mkIf (pos != null) {
              "pos" = pos;
            };
          };
          disp1_cfg = createDispCfg disp1 disp1_res disp1_pos;
          disp2_cfg = createDispCfg disp2 disp2_res disp2_pos;
        in {
        # Does not work, dont know why
        #  "*" = {
        #    bg = "${XDG_CONFIG_HOME:-$HOME/.config}/sway/backgrounds/cheatsheet.jpg fit";
        #  };
        } // (disp2_cfg // disp1_cfg);

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
            # Firefox sharing indicator
            { app_id = "^firefox$"; title = "^Firefox — Sharing Indicator$"; }
            # File dialogs
            { app_id = "^xdg-desktop-portal-gtk$"; }
            # Astroid file dialog
            { app_id = "^astroid$"; title = "^Save attachment to folder..$"; }
            # Keepass browser access requests 
            { app_id = "^org.keepassxc.KeePassXC$"; title = "^KeePassXC - Browser Access Request$"; }
            # Cura dialogs
            { app_id = "^com\/.https:\/\/ultimaker.python3$"; title = "^Multiply Selected Model$"; }
            # Zoom fixes
            { title = "^.zoom$"; app_id = "$"; }
            { title = "^zoom$"; app_id = "$"; }
            { title = "^Settings$"; app_id = "$"; }
            { title = "^Polls$"; app_id = "$"; }
            { title = "^as_toolbar$"; app_id = "$"; }
            { title = "^Select a window or an application that you want to share$"; app_id = "$"; }
          ];
        };

      };

      extraConfig = ''
        # restarts some user services to make sure they have the correct environment variables
        exec "systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr; systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr"
      '' + lib.optionalString (laptopDisplay != null) ''
        bindswitch --reload --locked lid:on output ${laptopDisplay} disable
        bindswitch --reload --locked lid:off output ${laptopDisplay} enable
      '' + ''
        #output * bg ''\${XDG_CONFIG_HOME:-''\$HOME/.config}/sway/backgrounds/cheatsheet.jpg fit
        # credits for the image go to: https://www.youtube.com/watch?v=Lqz5ZtiCmYk
        output * bg ''\${XDG_CONFIG_HOME:-''\$HOME/.config}/sway/backgrounds/die_shot.jpg fit
      '' + lib.optionalString (cfg.sway.extraConfig != null) cfg.sway.extraConfig;
    };

    systemd.user.services = let
      createStartupServices = progs: builtins.listToAttrs (map (
        p: {
          "name" = "${p.serviceName}";
          "value" = {
            Unit = rec {
              Requires = [ "tray.target" ];
              After = [ "graphical-session-pre.target" "tray.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              Type = "simple";
              ExecStart = p.command;
            } // (lib.optionalAttrs ((p.precommand or "") != "") {
              ExecStartPre = p.precommand;
            }) // (lib.optionalAttrs ((builtins.length (p.env or [])) != 0) {
              Environment = p.env;
            });
            Install = { WantedBy = [ "graphical-session.target" ]; };
          };
        }
      ) progs);
    in lib.optionalAttrs enableSystemdSway (createStartupServices startupPrograms);

    # Autostart sway in zsh
    programs.zsh.initExtra = if (!enableSystemdSway) then ''
      # If running from tty1 start sway
      [[ "$(tty)" == /dev/tty1 ]] && exec systemd-cat --identifier=sway sway
    '' else lib.mkOverride 1001 "";

    services.swayidle = {
      enable = enableSystemdSway;
      events = [
        { event = "before-sleep"; command = lockcmd; }
      ];

      timeouts = [
        { timeout = lockTimeout; command = lockcmd; }
        {
          timeout = disableDisplayTimeout;
          command = disableDisplayCmdRaw;
          resumeCommand = enableDisplayCmdRaw;
        }
      ];
    };

    # Empty dummy file to create the folder needed to store screenshots
    home.file."screenshots/.keep".text = "";

    xdg.configFile."swaylock/config".source = ../configs/swaylock/config;
    xdg.configFile."sway/scripts".source = ../configs/sway/scripts;
    xdg.configFile."sway/backgrounds".source = ../configs/sway/backgrounds;
  };
}
