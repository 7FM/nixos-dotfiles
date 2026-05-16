{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  myTools = pkgs.myTools { inherit osConfig; };

  createPasswordLookupCmd = searchTerm: [
    "${pkgs.libsecret}/bin/secret-tool"
    "lookup"
    "calendar"
    "${searchTerm}"
  ];

  # calendar sync program config
  vdirsyncer = {
    enable = true;
  };

  createCalendarAcc =
    name: remote:
    {
      readOnly ? false,
    }:
    {
      inherit
        vdirsyncer
        remote
        ;
      thunderbird = {
        enable = true;
        inherit readOnly;
      };
      primary = false;
      local.type = "filesystem";
      local.fileExt = ".ics";
    };

  enable = osConfig.custom.hm.modules.calendar.enable;
in
{
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      libsecret # Needed for secret-tool
    ];

    programs.vdirsyncer.enable = true;
    services.vdirsyncer = {
      enable = true;
      frequency = "*:0/15";
    };

    accounts.calendar = {
      basePath = "${config.xdg.dataHome}/cal";
      accounts = myTools.getSecret ../configs "calendar/accounts.nix" {
        inherit createPasswordLookupCmd createCalendarAcc;
      };
    };

  };
}
