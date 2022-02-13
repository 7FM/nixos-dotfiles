{ config, pkgs, lib, ... }:

let
  cfg = config.custom.hm.modules;

  laptopDisplay = cfg.sway.laptopDisplay;
  disp1 = cfg.sway.disp1;
  disp2 = if cfg.sway.disp2 == null then disp1 else cfg.sway.disp2;
  usesVirtualbox = cfg.sway.virtualboxWorkaround;

  #lockcmd = "swaylock -f -c 000000";
  lockcmd = "swaylock";
  #disableDisplayCmd = "timeout 600 'swaymsg \"output * dpms off\"'";
  disableDisplayCmd = "";
  enableDisplayCmd = "resume 'swaymsg \"output * dpms on\"'";

  enableSystemdSway = false;
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

        menu = "wofi --show=drun --lines=5 --prompt=\"\"";

        terminal = (if usesVirtualbox then "LIBGL_ALWAYS_SOFTWARE=1 " else "") + "alacritty";

        modifier = mod;

        keybindings = lib.mkOptionDefault ({
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
        } // (lib.optionalAttrs (laptopDisplay != null) {
          # Brightness control
          "XF86MonBrightnessDown" = "exec \"brightnessctl set 2%-\"";
          "XF86MonBrightnessUp" = "exec \"brightnessctl set +2%\"";
        }) // createWsKeybindings workspaces);

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
          ++ lib.optional (laptopDisplay != null) { command = "''\${XDG_CONFIG_HOME:-''\$HOME/.config}/sway/scripts/clamshell_mode_fix.sh ${laptopDisplay}"; always = true; }
          ++ [
          # start usually used programs
          { command = "astroid"; always = false; }
          { command = "mattermost-desktop"; always = false; }
          { command = "keepassxc"; always = false; }
          { command = "wpa_gui -t"; always = false; }
          { command = "blueman-applet"; always = false; }
        ];

        assigns = lib.optionalAttrs (disp1 != disp2) {
          "12:A2" = [ { app_id = "^astroid$"; } ];
          "19:A9" = [ { class = "^Mattermost$"; } ];
          "20:A10" = [ { app_id = "^org.keepassxc.KeePassXC$"; } ];
        } // lib.optionalAttrs (disp1 == disp2) {
          "2" = [ { app_id = "^astroid$"; } ];
          "9" = [ { class = "^Mattermost$"; } ];
          "10" = [ { app_id = "^org.keepassxc.KeePassXC$"; title = "^(?!Unlock Database - KeePassXC$)"; } ];
        };

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
            # File dialogs
            { title = "Save"; app_id = "^xdg-desktop-portal-gtk$"; }
            { title = "Open"; app_id = "^xdg-desktop-portal-gtk$"; }
            # Zoom fixes
            { title = "^zoom$"; app_id = "$"; }
            { title = "^Settings$"; app_id = "$"; }
            { title = "^Polls$"; app_id = "$"; }
            { title = "^as_toolbar$"; app_id = "$"; }
            { title = "^Select a window or an application that you want to share$"; app_id = "$"; }
          ];
        };

      };

      extraConfig = lib.optionalString (laptopDisplay != null) ''
        bindswitch --reload --locked lid:on output ${laptopDisplay} disable
        bindswitch --reload --locked lid:off output ${laptopDisplay} enable
      '' + ''
        #output * bg ''\${XDG_CONFIG_HOME:-''\$HOME/.config}/sway/backgrounds/cheatsheet.jpg fit
        # credits go to: https://www.youtube.com/watch?v=Lqz5ZtiCmYk
        output * bg ''\${XDG_CONFIG_HOME:-''\$HOME/.config}/sway/backgrounds/die_shot.jpg fit
      '';
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

    # Empty dummy file to create the folder needed to store screenshots
    home.file."screenshots/.keep".text = "";

    xdg.configFile."swaylock/config".source = ../configs/swaylock/config;
    xdg.configFile."sway/scripts".source = ../configs/sway/scripts;
    xdg.configFile."sway/backgrounds".source = ../configs/sway/backgrounds;
  };
}
