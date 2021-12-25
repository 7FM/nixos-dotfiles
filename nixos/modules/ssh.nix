{ config, pkgs, lib, ... }:

let
  runHeadless = config.custom.gui == "headless";

  cfg = config.custom.sshServer;
  enable = cfg.enable;
  _ports = cfg.ports;
  ports = if lib.types.path.check _ports then (import _ports) else _ports;
  myTools = pkgs.myTools { inherit config pkgs lib; };
in {
  options.custom.sshServer = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Specifies whether a ssh server should be run!
        This is automagically enabled when running in headless mode.
      '';
    };
    ports = mkOption {
      type = types.either types.path (types.nonEmptyListOf types.string);
      default = myTools.getSecretPath ../. "sshPorts.nix";
      description = ''
        Specifies the ports on which the ssh server should listen!
      '';
    };
  };

  config = {
    # Enable the OpenSSH daemon.
    services.openssh.enable = enable || runHeadless;
    services.openssh.ports = ports;
    services.openssh.permitRootLogin = "no";
    services.openssh.passwordAuthentication = false;

    # Start ssh agent to manage the ssh keys
    programs.ssh.startAgent = !runHeadless;
  };
}
