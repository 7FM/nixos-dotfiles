{ config, pkgs, lib, ... }:

let
  tools = import ../common/lib { inherit config pkgs lib; };

  createPasswordLookupCmd = searchTerm: "secret-tool lookup email ${searchTerm}";

  offlineimapConf = emailAddr: shortTag: customHook: hasIMAP: {
    enable = hasIMAP;
    postSyncHookCommand = ''
      notmuch new
      notmuch tag -inbox +sent from:${emailAddr}
      notmuch tag +${shortTag} to:${emailAddr}
      notmuch tag -unread 'date:..30d' tag:unread
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

  generateMailDirSentFolders = emailAddresses: let
    emailAccountNames = builtins.attrNames emailAddresses;
    basePath = config.accounts.email.maildirBasePath;
    emailAccountSentDirPaths = builtins.map (acc: let
        accountSettings = builtins.getAttr acc config.accounts.email.accounts;
        sentDirOffset = "/" + accountSettings.folders.sent + "/cur";
      in basePath + ("/" + acc) + sentDirOffset
    ) emailAccountNames;

    keepFileName = "/.keep";
    keepFileSettings = { text = ""; };
    emailAccountSentDirKeepFilePaths = builtins.map (p: {
      name = p + keepFileName;
      value = keepFileSettings;
    }) emailAccountSentDirPaths;

    sentDirs = builtins.listToAttrs emailAccountSentDirKeepFilePaths;
  in
    sentDirs;

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
      externalEditor = "alacritty -e nvim -c 'set ft=mail' '+set fileencoding=utf-8' '+set ff=unix' '+set enc=utf-8' '+set fo+=w' %1";
      extraConfig = {
        # poll.interval = 0;
        poll.interval = 180;
        editor = {
          attachment_words = "attach,anbei,anhang,angehängt";
          save_draft_on_force_quit = true;
        };
        startup.queries = tools.getSecret ../configs "email/startupQueries.nix";
      };
    };
    xdg.configFile."astroid/hooks".source = ../configs/astroid/hooks;
    xdg.configFile."astroid/keybindings".source = ../configs/astroid/keybindings;

    # Email indexer
    programs.notmuch.enable = true;
    # Email fetcher
    programs.offlineimap.enable = true;
    # Email sender
    programs.msmtp.enable = true;

    accounts.email.accounts = tools.getSecret ../configs "email/emailAddresses.nix" { inherit createPasswordLookupCmd offlineimapConf notmuchConf astroidConf msmtpConf; };

    home.file = generateMailDirSentFolders config.accounts.email.accounts;
  };
}
