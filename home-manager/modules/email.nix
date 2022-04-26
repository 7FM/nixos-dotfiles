{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };

  createPasswordLookupCmd = searchTerm: "secret-tool lookup email ${searchTerm}";

  offlineimapConf = emailAddr: shortTag: customHook: hasIMAP: {
    enable = hasIMAP;
    postSyncHookCommand = ''
      notmuch new
      notmuch tag -inbox +sent from:${emailAddr}
      notmuch tag +${shortTag} to:${emailAddr}
      notmuch tag -unread 'date:..30d' tag:unread
      ${customHook}
      afew --tag --new
      notifymuch
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

  generateMailDirFolders = emailAddresses: let
    emailAccountNames = builtins.attrNames emailAddresses;
    basePath = config.accounts.email.maildirBasePath;
    emailDirPathsGen = folder: builtins.map (acc: let
        accountSettings = builtins.getAttr acc emailAddresses;
        folderPath = builtins.getAttr folder accountSettings.folders;
        sentDirOffset = "/" + folderPath + "/cur";
      in basePath + ("/" + acc) + sentDirOffset
    ) emailAccountNames;
    emailAccountSentDirPaths = emailDirPathsGen "sent";
    emailAccountDraftsDirPaths = emailDirPathsGen "drafts";
    emailAccountInboxDirPaths = emailDirPathsGen "inbox";
    emailAccountTrashDirPaths = emailDirPathsGen "trash";

    keepFileName = "/.keep";
    keepFileSettings = { text = ""; };
    emailAccountKeepFilePathGen = x : builtins.map (p: {
      name = p + keepFileName;
      value = keepFileSettings;
    }) x;

    keepFiles = emailAccountKeepFilePathGen emailAccountSentDirPaths ++
                emailAccountKeepFilePathGen emailAccountDraftsDirPaths ++
                emailAccountKeepFilePathGen emailAccountInboxDirPaths ++
                emailAccountKeepFilePathGen emailAccountTrashDirPaths;

    sentDirs = builtins.listToAttrs keepFiles;
  in
    sentDirs;

  enable = config.custom.hm.modules.email.enable;
in {
  config = lib.mkIf enable {
    home.packages = with pkgs; [
      libsecret # Needed for secret-tool
      python3Packages.notifymuch
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
          attachment_words = "attach,anbei,anhang,angehängt,angefügt";
          save_draft_on_force_quit = true;
        };
        general.time = {
            clock_format = "24h";
        };
        startup.queries = myTools.getSecret ../configs "email/startupQueries.nix";
      };
    };
    xdg.configFile."astroid/hooks".source = ../configs/astroid/hooks;
    xdg.configFile."astroid/keybindings".source = ../configs/astroid/keybindings;

    # Email indexer
    programs.notmuch.enable = true;
    # Email initial tagging script
    programs.afew = {
      enable = true;
    };
    # Email fetcher
    programs.offlineimap.enable = true;
    # Email sender
    programs.msmtp.enable = true;

    accounts.email.accounts = myTools.getSecret ../configs "email/emailAddresses.nix" { inherit createPasswordLookupCmd offlineimapConf notmuchConf astroidConf msmtpConf; };

    home.file = generateMailDirFolders config.accounts.email.accounts;
  };
}
