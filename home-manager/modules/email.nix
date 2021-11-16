{ config, pkgs, lib, ... }:

let
  createPasswordLookupCmd = searchTerm: "secret-tool lookup email ${searchTerm}";

  offlineimapConf = emailAddr: shortTag: customHook: hasIMAP: {
    enable = hasIMAP;
    postSyncHookCommand = ''
      notmuch new
      notmuch tag -inbox +sent from:${emailAddr}
      notmuch tag +${shortTag} to:${emailAddr}
      ${customHook}
    '';
  };

  astroidConf = emailAddr: {
    enable = true;
    # sendMailCommand = ''
    #   msmtpq --read-envelope-from --read-recipients --account=${emailAddr}
    # '';
  };

  msmtpConf = emailAddr: hasSMTP: {
    enable = hasSMTP;
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

    # Email frontend
    # programs.alot.enable = true;
    # TODO might need: GDK_BACKEND=x11
    programs.astroid = {
      enable = true;
      pollScript = ''
        # check if we have a connection
        if ! ping -w 1 -W 1 -c 1 nixos.org; then
            echo "there is no internet connection"
            exit
        fi

        offlineimap
      '';
      extraConfig = {
        # poll.interval = 0;
        poll.interval = 180;
        editor.attachment_words = "attach,anbei,anhang,angehängt";
      };
    };
    # Email indexer
    programs.notmuch.enable = true;
    # Email fetcher
    programs.offlineimap.enable = true;
    # Email sender
    programs.msmtp.enable = true;

    accounts.email.accounts = import ../configs/secrets/email/emailAddresses.nix { inherit createPasswordLookupCmd offlineimapConf notmuchConf astroidConf msmtpConf; };
  };
}
