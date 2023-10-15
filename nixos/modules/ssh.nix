userName:
{ config, pkgs, lib, ... }:

let
  runHeadless = config.custom.gui == "headless";

  cfg = config.custom.sshServer;
  enable = cfg.enable;
  _ports = cfg.ports;
  ports = if lib.types.path.check _ports then (import _ports) else _ports;
  myTools = pkgs.myTools { osConfig = config; };
  authorizedKeys = cfg.authorizedKeys;
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
      type = types.either types.path (types.nonEmptyListOf types.ports);
      default = myTools.collectPorts (((myTools.getSecret ../. "usedPorts.nix") myTools) // {ssh = [];}).ssh;
      description = ''
        Specifies the ports on which the ssh server should listen!
      '';
    };
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = myTools.getSecret ../. "userAuthorizedSSHKeys.nix";
      description = ''
        A list of verbatim OpenSSH public keys that should be added to the
        user's authorized keys. The keys are added to a file that the SSH
        daemon reads in addition to the the user's authorized_keys file.
        You can combine the <literal>keys</literal> and
        <literal>keyFiles</literal> options.
        Warning: If you are using <literal>NixOps</literal> then don't use this
        option since it will replace the key required for deployment via ssh.
      '';
      example = [
        "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
        "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
      ];
    };
  };

  config = {
    # Enable the OpenSSH daemon.
    services.openssh.enable = enable || runHeadless;
    services.openssh.ports = ports;
    services.openssh.settings.PermitRootLogin = "no";
    services.openssh.settings.PasswordAuthentication = false;
    users.users."${userName}".openssh.authorizedKeys.keys = authorizedKeys;

    # Start ssh agent to manage the ssh keys
    programs.ssh.startAgent = !runHeadless;
  };
}
