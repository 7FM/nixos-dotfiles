{ config, pkgs, lib, ... }:

let
  createPasswordLookupCmd = searchTerm: "secret-tool lookup email ${searchTerm}";

  offlineimapConf = emailAddr: {
    enable = true;
    postSyncHookCommand = ''
      notmuch new
      notmuch tag -inbox +sent from:${emailAddr}
    '';
  };

  notmuchConf = {
    enable = true;
  };

  enable = config.custom.hm.modules.email.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      gnome.libsecret # Needed for secret-tool
    ];

    programs.alot.enable = true;
    programs.notmuch.enable = true;
    programs.offlineimap.enable = true;

    accounts.email.accounts = import ../configs/secrets/email/emailAddresses.nix { inherit createPasswordLookupCmd offlineimapConf notmuchConf; };
  };
}
