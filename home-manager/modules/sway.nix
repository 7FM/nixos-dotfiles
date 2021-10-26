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

in {
  home.packages = with pkgs; [
    # needed for waybar customization
    font-awesome
  ] ++ lib.optional enableSystemdSway (import ../common/sway_extra_packages.nix { inherit pkgs; });

  wayland.windowManager.sway = {
    enable = enableSystemdSway;
    wrapperFeatures.gtk = true;
    xwayland = true;
    systemdIntegration = true;
    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING="1"
      export SDL_VIDEODRIVER="wayland"
      export XDG_SESSION_TYPE="wayland"
      # QT needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM="wayland-egl"
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      # Elementary/EFL
      export ECORE_EVAS_ENGINE="wayland_egl"
      export ELM_ENGINE="wayland_egl"
      # Fix message: [wlr] [libseat] [libseat/backend/seatd.c:70] Could not connect to socket /run/seatd.sock: no such file or directory
      export LIBSEAT_BACKEND="logind"
      #export SUDO_ASKPASS="${pkgs.ksshaskpass}/bin/ksshaskpass"
      #export SSH_ASKPASS="${pkgs.ksshaskpass}/bin/ksshaskpass"
      export MOZ_DBUS_REMOTE="1"
    '';

    config = {
      menu = "wofi --show=drun --lines=5 --prompt=\"\"";
      terminal = "alacritty";
      #terminal = "LIBGL_ALWAYS_SOFTWARE=1 alacritty";
      modifier = "Mod4";

      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
        mod2 = if (mod == "Mod4") then "Mod1" else "Mod4";
      in lib.mkOptionDefault {
        # Brightness control
        "XF86MonBrightnessDown" = "exec \"brightnessctl set 2%-\"";
        "XF86MonBrightnessUp" = "exec \"brightnessctl set +2%\"";
        # Volume control
        "XF86AudioRaiseVolume" = "exec \"pactl set-sink-volume @DEFAULT_SINK@ +1%\"";
        "XF86AudioLowerVolume" = "exec \"pactl set-sink-volume @DEFAULT_SINK@ -1%\"";
        "XF86AudioMute" = "exec \"pactl set-sink-mute @DEFAULT_SINK@ toggle\"";
        # Lockout hotkey
        "${mod}+${mod2}+l" = "exec ${lockcmd}";
        # Screenshots
        "Print" = "exec grim ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png";
        # Take a screenshot of a selected region
        "${mod}+Print" = "exec grim -g \"$(slurp)\" ~/screenshots/$(date +%Y-%m-%d_%H-%m-%s).png";
      };

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
      ] ++ lib.optional desktop { command = "swaymsg focus output DVI-D-1"; always = false; }
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
        "DVI-D-1" = {
          res = "1920x1080@144Hz";
          pos = "0,0";
        };
        "HDMI-A-1" = {
          res = "1920x1080";
          pos = "1920,0";
        };
      };

      # Default assign workspaces to outputs
      workspaceOutputAssign = if desktop then [
        { workspace = "1"; output = "DVI-D-1"; }
        { workspace = "2"; output = "DVI-D-1"; }
        { workspace = "3"; output = "DVI-D-1"; }
        { workspace = "4"; output = "DVI-D-1"; }
        { workspace = "5"; output = "DVI-D-1"; }
        { workspace = "6"; output = "HDMI-A-1"; }
        { workspace = "7"; output = "HDMI-A-1"; }
        { workspace = "8"; output = "HDMI-A-1"; }
        { workspace = "9"; output = "HDMI-A-1"; }
        { workspace = "10"; output = "HDMI-A-1"; }
      ] else [];

      gaps = {
        inner = 2;
        smartGaps = true;
        smartBorders = true;
      };

      floating = {
        criteria = [
          { title = "Steam - Update News"; }
          { app_id = "pavucontrol"; }
          { app_id = "nm-connection-editor"; }
          { title = "Print"; }
          { title = "wpa_gui"; }
          # Zoom fixes
          { title = "zoom"; }
          { title = "Settings"; }
          { title = "Select a window or an application that you want to share"; }
        ];
      };

    };

    extraConfig = lib.optionalString (laptopDisplay != null) ''
      bindswitch --reload --locked lid:on output ${laptopDisplay} disable
      bindswitch --reload --locked lid:off output ${laptopDisplay} enable
    '' + ''
      output * bg ~/.config/sway/backgrounds/cheatsheet.jpg fit
      # Import the most important environment variables into the D-Bus and systemd
      # user environments (e.g. required for screen sharing and Pinentry prompts):
      #exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
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

  home.file.".config/sway".source = ../configs/sway;
  #home.file.".config/sway/config".source = ../configs/sway/config;
  #home.file.".config/sway/scripts".source = ../configs/sway/scripts;
  #home.file.".config/sway/backgrounds".source = ../configs/sway/backgrounds;
  home.file.".config/wofi".source = ../configs/wofi;
  home.file.".config/waybar".source = ../configs/waybar;
  home.file.".config/wlogout".source = ../configs/wlogout;
}
