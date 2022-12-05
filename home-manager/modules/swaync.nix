{ config, pkgs, lib, ... }:

let
  hmManageSway = config.custom.gui == "hm-wayland";
  enable = hmManageSway || (config.custom.gui == "wayland");
in {
  config = lib.mkIf enable {

    xdg.configFile."swaync/style.css".source = ../configs/swaync/style.css;
    xdg.configFile."swaync/config.json".text = let 
      conf = {
        "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json";
        "positionX" = "right";
        "positionY" = "top";
        "control-center-margin-top" = 8;
        "control-center-margin-bottom" = 8;
        "control-center-margin-right" = 8;
        "control-center-margin-left" = 8;
        "control-center-width" = 500;
        "control-center-height" = 600;
        "fit-to-screen" = false;
        "layer" = "overlay";
        "cssPriority" = "user";
        "notification-icon-size" = 64;
        "notification-body-image-height" = 100;
        "notification-body-image-width" = 200;
        "timeout" = 5;
        "timeout-low" = 2;
        "timeout-critical" = 0;
        "notification-window-width" = 500;
        "keyboard-shortcuts" = true;
        "image-visibility" = "when-available";
        "transition-time" = 200;
        "hide-on-clear" = true;
        "hide-on-action" = true;
        "script-fail-notify" = true;
        "widgets" = [
          "title"
          "dnd"
          "mpris"
          "notifications"
        ];
        "widget-config" = {
          "title" = {
            "text" = "Notifications";
            "clear-all-button" = true;
            "button-text" = "Clear All";
          };
          "dnd" = {
            "text" = "Do Not Disturb";
          };
          "label" = {
            "max-lines" = 5;
            "text" = "Label Text";
          };
          "mpris" = {
            "image-size" = 96;
            "image-radius" = 12;
          };
        };
      };
    in builtins.toJSON conf;
  };
}
