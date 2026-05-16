{
  config,
  lib,
  ...
}:

let
  enable = config.custom.gui.hyprland;
in
{
  config = lib.mkIf enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # PAM entry required for hyprlock
    security.pam.services.hyprlock = { };
  };
}
