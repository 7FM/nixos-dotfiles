{ pkgs, createPasswordLookupCmd, offlineimapConf, notmuchConf, astroidConf, msmtpConf }:

{
  # Take a look at https://nix-community.github.io/home-manager/options.html#opt-accounts.email.accounts
  # for all available options, but it typically looks like that:

  "my_mail" = rec {
    address = "my_mail@my_mail.com";
    userName = "my_mail";
    passwordCommand = createPasswordLookupCmd address;
    realName = "My Name";
    primary = true;

    flavor = "plain";
    # Google mail uses non standard protocol implementations
    #flavor = "gmail.com";

    imap = {
      host = "imap.my_mail.com";
      port = 993;
      tls = {
        enable = true;
        useStartTls = true;
      };
    };
    smtp = {
      host = "smtp.my_mail.com";
      port = 587;
      tls = {
        enable = true;
        useStartTls = true;
      };
    };
    notmuch.enable = true;
    # Parameters: emailAddr: shortTag: customHook: hasIMAP:
    offlineimap = offlineimapConf false address "my_mail" "" (imap != null);
    # Parameters: emailAddr:
    astroid = astroidConf address;
    # Parameters: emailAddr: hasSMTP:
    msmtp = msmtpConf address (smtp != null);
  };
}
