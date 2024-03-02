{ khalConfig, createCalendarAcc, createPasswordLookupCmd }:

let
  calDavServer = urlSuffix: rec {
    url = "https://definitelyMyServerDomain.com/${userName}/${urlSuffix}";
    userName = "DefinitelyMyUsername";
    passwordCommand = createPasswordLookupCmd "myCalDavServerPwdLookupEntry";
    type = "caldav"; # "http", "google_calendar"
  };

in {
  "Private" = (createCalendarAcc "Private" (ownCalDavServer "MyCalDavCalendarID") (khalConfig { color = "magenta"; })) // {
    primary = true;
    primaryCollection = "Private";
  };
  "Bdays" = createCalendarAcc "Bdays" (ownCalDavServer "MyCalDavBDayCalendarID") (khalConfig { color = "dark green"; priority = 20; });
}
