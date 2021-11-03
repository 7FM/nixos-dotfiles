{ config, pkgs, lib, ... }:

{
  xdg = {
    enable = true; # This sets environment variables such as: XDG_CACHE_HOME, XDG_CONFIG_HOME and XDG_DATA_HOME
  };
}
