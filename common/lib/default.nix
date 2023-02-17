deviceName:
{ osConfig }:

rec {
  getSecretPath = let
    dummySecrets = osConfig.custom.useDummySecrets;
    secretsFolder = if dummySecrets then "/example_secrets" else "/secrets";
  in basePath: offsetPath: let
    secretsBase = basePath + secretsFolder;
    generalSecretPath = secretsBase + ("/" + offsetPath);

    # determine the device specific secret path
    deviceSecretsBase = secretsBase + ("/" + deviceName);
    deviceSecretPath = deviceSecretsBase + ("/" + offsetPath);

    # Prefer the device specific secret path (if it exists) over the common secrets path
    secretPath = if (builtins.pathExists deviceSecretPath) then deviceSecretPath else generalSecretPath;
  in
    secretPath;

  getSecret = basePath: offsetPath:
    import (
      getSecretPath basePath offsetPath
    );
}
