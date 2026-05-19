{
  config,
  pkgs,
  lib,
  osConfig,
  nix-index-database,
  ...
}:

let
  enable = osConfig.custom.hm.modules.nix_index.enable;
in
{
  imports = [ nix-index-database.homeModules.nix-index ];

  config = lib.mkIf enable {
    programs.nix-index = {
      enable = true;
      enableZshIntegration = osConfig.custom.hm.modules.zsh.enable;
      enableBashIntegration = osConfig.custom.hm.modules.bash.enable;
    };
    programs.nix-index-database.comma.enable = true;
  };
}
