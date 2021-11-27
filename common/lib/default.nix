{ config, lib, pkgs, ... }:

{
  getSecret = let
    dummySecrets = config.custom.useDummySecrets;
  in basePath: offsetPath:
    import (
      basePath +
      (if dummySecrets then "/example_secrets" else "/secrets") +
      ("/" + offsetPath)
    );
}
