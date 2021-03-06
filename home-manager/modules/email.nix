{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };

  createPasswordLookupCmd = searchTerm: "${pkgs.libsecret}/bin/secret-tool lookup email ${searchTerm}";

  offlineimapConf = emailAddr: shortTag: customHook: hasIMAP: {
    enable = hasIMAP;
    postSyncHookCommand = ''
      ${pkgs.notmuch}/bin/notmuch new
      ${pkgs.notmuch}/bin/notmuch tag -inbox +sent from:${emailAddr}
      ${pkgs.notmuch}/bin/notmuch tag +${shortTag} to:${emailAddr}
      ${pkgs.notmuch}/bin/notmuch tag -unread 'date:1970..30d' tag:unread
      ${customHook}
      ${pkgs.afew}/bin/afew --tag --new
      ${pkgs.python3Packages.notifymuch}/bin/notifymuch
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
    ];

    # Email frontend
    # programs.alot.enable = true;

    systemd.user.services.startup-astroid.Service.Environment = let
      requiredPkgsList = with pkgs; [
        # required for other hooks
        bash
        # required for sending mails
        msmtp
        coreutils # sleep
        netcat # nc
        which
      ];
    in [
      # List all required packages here!
      "PATH=${lib.makeBinPath requiredPkgsList}"
      # non default notmuch config location needs to be advertised!
      "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/default/config"
      # env vars for the send mail queue
      "MSMTP_QUEUE=${config.xdg.dataHome}/msmtp/queue"
      "MSMTP_LOG=${config.xdg.dataHome}/msmtp/queue.log"
    ];

    programs.astroid = {
      enable = true;
      pollScript = ''
        # check if we have a connection
        if ! ${pkgs.iputils}/bin/ping -w 1 -W 1 -c 1 nixos.org; then
            echo "there is no internet connection"
            exit
        fi

        ${pkgs.offlineimap}/bin/offlineimap
      '';
      externalEditor = "${pkgs.alacritty}/bin/alacritty -e ${config.programs.neovim.finalPackage}/bin/nvim -c 'set ft=mail' '+set fileencoding=utf-8' '+set ff=unix' '+set enc=utf-8' '+set fo+=w' %1";
      extraConfig = {
        # poll.interval = 0;
        poll.interval = 180;
        editor = {
          attachment_words = "attach,anbei,anhang,angeh??ngt,angef??gt";
          save_draft_on_force_quit = true;
        };
        general.time = {
            clock_format = "24h";
        };
        startup.queries = myTools.getSecret ../configs "email/startupQueries.nix";
      };
    };
    xdg.configFile."astroid/keybindings".source = ../configs/astroid/keybindings;
    xdg.configFile."astroid/hooks/toggle" = {
      text = ''
        #!/usr/bin/env bash
        # Source: https://github.com/astroidmail/astroid/wiki/User-defined-keyboard-hooks#example-toggle-custom-tag-in-thread-index
        # get a tag as first argument and thread id as second argument
        #

        if [[ $(${pkgs.notmuch}/bin/notmuch search thread:$2 and tag:$1) ]]; then # check if the thread matches the tag
          echo "removing tag: $1 from thread:$2"                                  #
          ${pkgs.notmuch}/bin/notmuch tag -$1 thread:$2                           # remove the tag
        else
          echo "adding tag: $1 to thread:$2"                                      #
          ${pkgs.notmuch}/bin/notmuch tag +$1 thread:$2                           # add the tag
        fi
      '';
      executable = true;
    };
    xdg.configFile."astroid/hooks/togglemail" = {
      text = ''
        #!/usr/bin/env bash
        # Source: https://github.com/astroidmail/astroid/wiki/User-defined-keyboard-hooks#example-toggle-custom-tag-on-a-single-email-in-thread-view
        # get a tag as first argument and message id as second argument
        #

        if [[ $(${pkgs.notmuch}/bin/notmuch search id:$2 and tag:$1) ]]; then # check if the message matches the tag
          echo "removing tag: $1 from id:$2"                                  #
          ${pkgs.notmuch}/bin/notmuch tag -$1 id:$2                           # remove the tag
        else
          echo "adding tag: $1 to id:$2"                                      #
          ${pkgs.notmuch}/bin/notmuch tag +$1 id:$2                           # add the tag
        fi
      '';
      executable = true;
    };

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

    accounts.email.accounts = myTools.getSecret ../configs "email/emailAddresses.nix" { inherit createPasswordLookupCmd offlineimapConf notmuchConf astroidConf msmtpConf pkgs; };

    home.file = generateMailDirFolders config.accounts.email.accounts;
    xdg.configFile."notifymuch/notifymuch.cfg".text = ''
      [notifymuch]
      query = is:unread and not is:spam
      mail_client =
      recency_interval_hours = 12
      hidden_tags = inbox unread attachment replied sent encrypted signed
    '';
  };
}
