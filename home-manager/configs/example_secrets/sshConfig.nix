{ config, pkgs, lib, ... }:

# See: https://nix-community.github.io/home-manager/options.html#opt-programs.ssh.matchBlocks
# Example is also taken from there!
{
  # "john.example.com" = {
  #   hostname = "example.com";
  #   user = "john";
  # };
  # foo = lib.hm.dag.entryBefore ["john.example.com"] {
  #   hostname = "example.com";
  #   identityFile = "/home/john/.ssh/foo_rsa";
  # };
}
