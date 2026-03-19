{
  config,
  pkgs,
  lib,
  ...
}:

let
  anyWayland = config.custom.gui.sway || config.custom.gui.hyprland;
in
{

  config = lib.mkMerge [
    (lib.mkIf anyWayland {
      # Enable bluetooth manager when bluetooth is enabled
      services.blueman.enable = config.hardware.bluetooth.enable;

      services.xserver.desktopManager.xterm.enable = false;

      services.displayManager.gdm.enable = false;

      # SDDM
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      services.libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          scrollMethod = "twofinger";
          naturalScrolling = true;
        };
      };

      # Ensure the keyrings are opened
      security.pam.services.sddm.enableGnomeKeyring = true;
      security.pam.services.sddm-greeter.enableGnomeKeyring = true;
      security.pam.services.login.enableGnomeKeyring = true;

      programs.dconf.enable = true;

      fonts = {
        enableDefaultPackages = true;
        fontconfig.enable = true;
        fontconfig.defaultFonts = {
          serif = [ "DejaVu Serif" ];
          sansSerif = [ "DejaVu Sans" ];
          monospace = [ "DejaVu Sans Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
        packages = with pkgs; [
          libertine
          libertinus
          noto-fonts
          noto-fonts-color-emoji
          nerd-fonts.meslo-lg
          google-fonts
        ];
      };

      # Enable support for screen sharing
      services.pipewire.enable = true;
      xdg.portal = {
        enable = true;
        extraPortals =
          lib.optionals config.custom.gui.sway (with pkgs; [ xdg-desktop-portal-wlr ])
          ++ lib.optionals config.custom.gui.hyprland (with pkgs; [ xdg-desktop-portal-hyprland ])
          ++ (with pkgs; [ xdg-desktop-portal-gtk ]);
        config = lib.mkMerge (
          lib.optionals config.custom.gui.sway [
            { sway.default = [ "wlr" "gtk" ]; }
          ]
          ++ lib.optionals config.custom.gui.hyprland [
            { "Hyprland".default = [ "hyprland" "gtk" ]; }
          ]
        );
      };

      # Allow programs to request real-time priorities
      security.pam.loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
      ];
    })

    (lib.mkIf config.custom.gui.sway {
      xdg.portal.wlr.enable = true;
      security.pam.services.swaylock = { };
      services.displayManager.sessionPackages = with pkgs; [ sway ];
    })
  ];

}
