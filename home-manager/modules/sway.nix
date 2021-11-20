{ config, pkgs, lib, ... }:

let 
  desktop = true;
  laptopDisplay = null;

  #lockcmd = "swaylock -f -c 000000";
  lockcmd = "swaylock-fancy";
  #disableDisplayCmd = "timeout 600 'swaymsg \"output * dpms off\"'";
  disableDisplayCmd = "";
  enableDisplayCmd = "resume 'swaymsg \"output * dpms on\"'";

  enableSystemdSway = false;
  hmManageSway = config.custom.gui == "hm-wayland";

  enable = hmManageSway || (config.custom.gui == "wayland");
in {
  config = lib.mkIf enable {
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

        disp1 = "DVI-D-1";
        disp2 = "HDMI-A-1";

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

        terminal = "alacritty";
        #TODO change for virtualbox host!
        #terminal = "LIBGL_ALWAYS_SOFTWARE=1 alacritty";

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
        ] ++ lib.optional desktop { command = "swaymsg focus output ${disp1}"; always = false; }
          ++ lib.optional (laptopDisplay != null) { command = "~/.config/sway/scripts/clamshell_mode_fix.sh ${laptopDisplay}"; always = true; };

        bars = [
          {
            command = "${pkgs.waybar}/bin/waybar";
          }
        ];

        # Input settings
        input = {
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
        #    bg = "~/.config/sway/backgrounds/cheatsheet.jpg fit";
        #  };
        } // lib.mkIf desktop {
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
        output * bg ~/.config/sway/backgrounds/cheatsheet.jpg fit
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

    # This enables discovering fonts that where installed with home.packages
    fonts.fontconfig.enable = true;

    # Empty dummy file to create the folder needed to store screenshots
    home.file."screenshots/.keep".text = "";

    home.file.".config/sway/scripts".source = ../configs/sway/scripts;
    home.file.".config/sway/backgrounds".source = ../configs/sway/backgrounds;
    home.file.".config/wofi".source = ../configs/wofi;
    home.file.".config/waybar".source = ../configs/waybar;
    home.file.".config/wlogout".source = ../configs/wlogout;
  };
}
