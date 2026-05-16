{
  createCalendarAcc,
  createPasswordLookupCmd,
}:

let
  calDavServer = urlSuffix: rec {
    url = "https://definitelyMyServerDomain.com/${userName}/${urlSuffix}";
    userName = "DefinitelyMyUsername";
    passwordCommand = createPasswordLookupCmd "myCalDavServerPwdLookupEntry";
    type = "caldav"; # "http", "google_calendar"
  };

in
{
  "Private" =
    (createCalendarAcc "Private" (ownCalDavServer "MyCalDavCalendarID") { })
    // {
      primary = true;
    };
  "Bdays" = createCalendarAcc "Bdays" (ownCalDavServer "MyCalDavBDayCalendarID") { };
}
