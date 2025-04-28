{ config, pkgs, lib, osConfig, ... }:

let
  myTools = pkgs.myTools { inherit osConfig; };

  createPasswordLookupCmd = searchTerm: "${pkgs.libsecret}/bin/secret-tool lookup email ${searchTerm}";

  enable = osConfig.custom.hm.modules.email.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      libsecret # Needed for secret-tool
    ];

    programs.thunderbird = {
      enable = true;

      profiles = {
        "${config.home.username}" = {
          isDefault = true;
          search = {
            default = "ddg"; # DuckDuckGo
          };
        };
      };

      settings = {
        "general.useragent.override" = "";
        "privacy.donottrackheader.enabled" = true;
        "mailnews.start_page.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "mail.spam.manualMark" = true;
        "mail.SpellCheckBeforeSend" = true;
        "datareporting.policy.currentPolicyVersion" = 2;
        "datareporting.policy.dataSubmissionPolicyAcceptedVersion" = 2;
      };
    };

    accounts.email.accounts = myTools.getSecret ../configs "email/emailAddresses.nix" { inherit createPasswordLookupCmd; };
  };
}
