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
        # Override the weston compositor command so the greeter actually
        # renders a cursor. The default NixOS weston.ini for SDDM only
        # has [keyboard]/[libinput]; weston reads cursor theme/size from
        # a [shell] section, which we add here. SDDM's own [Theme]
        # CursorTheme/CursorSize are not propagated to weston.
        wayland.compositorCommand =
          let
            westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
              keyboard = {
                keymap_layout = "de";
                keymap_model = "pc104";
                keymap_options = "terminate:ctrl_alt_bksp";
                keymap_variant = "";
              };
              libinput = {
                enable-tap = true;
                left-handed = false;
              };
              shell = {
                cursor-theme = "Nordic-cursors";
                cursor-size = 24;
              };
            };
          in
          "${pkgs.weston}/bin/weston --shell=kiosk -c ${westonIni}";
      };
      # Expose the cursor theme so weston can resolve "Nordic-cursors".
      environment.systemPackages = [ pkgs.nordic ];
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
        # xdg-desktop-portal-hyprland is added by the NixOS hyprland
        # module itself (as cfg.portalPackage). Listing it again here
        # registers two store paths (the override-rebuilt one and the
        # bare one) for the same service file, breaking user-units.
        extraPortals =
          lib.optionals config.custom.gui.sway (with pkgs; [ xdg-desktop-portal-wlr ])
          ++ (with pkgs; [ xdg-desktop-portal-gtk ]);
        # programs.sway itself sets xdg.portal.config.sway.default = "gtk",
        # which conflicts with our richer "wlr;gtk" preference order.
        # mkForce keeps the value we actually want.
        config = lib.mkMerge (
          lib.optionals config.custom.gui.sway [
            { sway.default = lib.mkForce [ "wlr" "gtk" ]; }
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
      # Install sway system-wide so /run/current-system/sw/bin/sway exists
      # (UWSM's generated sway-uwsm.desktop hardcodes that path). HM alone
      # only places sway in the user profile, which UWSM cannot resolve.
      # The hyprland symlinkJoin trick to strip the non-UWSM .desktop
      # doesn't work here because programs.sway calls package.override.
      programs.sway.enable = true;
      programs.uwsm = {
        enable = true;
        waylandCompositors.sway = {
          prettyName = "Sway";
          comment = "Sway compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/sway";
        };
      };
    })
  ];

}
