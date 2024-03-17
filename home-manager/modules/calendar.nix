{ config, pkgs, lib, osConfig, ... }:

let
  myTools = pkgs.myTools { inherit osConfig; };

  createPasswordLookupCmd = searchTerm: ["${pkgs.libsecret}/bin/secret-tool" "lookup" "calendar" "${searchTerm}"];

  khalConfig = {color, priority ? 10, readOnly ? false, type ? "calendar"}: {
    enable = true;
    # Available colors: “black”, “white”, “brown”, “yellow”, “dark gray”, “dark green”, “dark blue”, “light gray”, “light green”, “light blue”, “dark magenta”, “dark cyan”, “dark red”, “light magenta”, “light cyan”, “light red”
    inherit color priority readOnly type;
    # type = "discover"; # Multiple calendars
    # type = "calendar"; # Single calendars
  };

  # calendar sync program config
  vdirsyncer = {
    enable = true;
  };

  createCalendarAcc = name: remote: khal: {
    inherit name vdirsyncer remote khal;
    primary = false;
    local.type = "filesystem";
    local.fileExt = ".ics";
  };

  enable = osConfig.custom.hm.modules.calendar.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      libsecret # Needed for secret-tool
    ];

    programs.vdirsyncer.enable = true;
    services.vdirsyncer = {
      enable = true;
      frequency = "*:0/15";
    };
    programs.khal = {
      enable = true;
    };

    accounts.calendar = {
      basePath = "${config.xdg.dataHome}/cal";
      accounts = myTools.getSecret ../configs "calendar/accounts.nix" { inherit createPasswordLookupCmd khalConfig createCalendarAcc; };
    };

  };
}
