{ config, lib, pkgs, ... }:

rec {
  getSecretPath = let
    dummySecrets = config.custom.useDummySecrets;
  in basePath: offsetPath:
    basePath +
    (if dummySecrets then "/example_secrets" else "/secrets") +
    ("/" + offsetPath);

  getSecret = let
    dummySecrets = config.custom.useDummySecrets;
  in basePath: offsetPath:
    import (
      getSecretPath basePath offsetPath
    );
}
