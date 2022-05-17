{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { inherit config pkgs lib; };
  enable = config.custom.gpu == "generic";
in {

}

