{
  config,
  pkgs,
  lib,
  ...
}:

# See: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ssh.settings
# Entries use native ssh_config directive names (HostName, User, IdentityFile, ...).
{
  # "john.example.com" = {
  #   HostName = "example.com";
  #   User = "john";
  # };
  # foo = lib.hm.dag.entryBefore ["john.example.com"] {
  #   HostName = "example.com";
  #   IdentityFile = "/home/john/.ssh/foo_rsa";
  # };
}
