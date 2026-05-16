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

  createCalendarAcc =
    name: remote:
    {
      readOnly ? false,
    }:
    {
      inherit remote;
      thunderbird = {
        enable = true;
        inherit readOnly;
      };
      primary = false;
    };

  enable = osConfig.custom.hm.modules.calendar.enable;
in
{
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      libsecret # Needed for secret-tool
    ];

    accounts.calendar = {
      basePath = "${config.xdg.dataHome}/cal";
      accounts = myTools.getSecret ../configs "calendar/accounts.nix" {
        inherit createPasswordLookupCmd createCalendarAcc;
      };
    };

  };
}
