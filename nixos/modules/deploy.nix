{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.custom.deploy;

  signingKeyName = "${config.networking.hostName}-deploy-1";
  secretKeyFile = "/etc/nix/deploy-signing-key.sec";
  publicKeyFile = "/etc/nix/deploy-signing-key.pub";

  # Public signing keys of all machines that are allowed to deploy.
  # A new deploy host generates its key pair on the first activation with
  # custom.deploy.host.enable = true, afterwards add the content of
  # /etc/nix/deploy-signing-key.pub here and roll it out to the targets.
  deployHostPublicKeys = [
    "nixos-desktop-deploy-1:rBXw/5RhosgSP1Cc0pnMe4HqZgM6nQfuq/WNgd+Xa2Q="
  ];
in
{
  options.custom.deploy = with lib; {
    host = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this machine is used to build and deploy the configuration
          of other machines (nixos-rebuild --target-host).
          Signs all locally built store paths and emulates the foreign
          architectures of the deploy targets.
        '';
      };
      emulatedSystems = mkOption {
        type = types.listOf types.str;
        default = [ "aarch64-linux" ];
        description = ''
          Foreign systems of deploy targets that are emulated via binfmt.
        '';
      };
    };

    target = {
      enable = mkOption {
        type = types.bool;
        default = config.custom.gui.headless;
        description = ''
          Whether this machine accepts store paths that were built and signed
          by one of the deploy hosts.
        '';
      };
      trustedPublicKeys = mkOption {
        type = types.listOf types.str;
        default = deployHostPublicKeys;
        description = ''
          Public signing keys of the deploy hosts that are trusted.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.host.enable {
      # Register qemu-user so this machine can build the configurations of
      # foreign targets, e.g. the raspberry pis (nixos-octoprint, ...), locally
      # instead of on the target itself.
      # Their kernel comes from nixos-hardware, which no hydra jobset builds,
      # so it is never in cache.nixos.org and has to be compiled on every
      # toolchain bump. Emulated that is still far quicker than on the pi.
      # This also adds the systems to nix.settings.extra-platforms.
      boot.binfmt.emulatedSystems = lib.filter (
        s: s != pkgs.stdenv.hostPlatform.system
      ) cfg.host.emulatedSystems;

      # Sign locally built store paths, so that the deploy targets accept them
      # from an unprivileged ssh user.
      nix.settings.secret-key-files = [ secretKeyFile ];

      # The secret key must never end up in the nix store: create it on the
      # first activation, i.e. before the nix-daemon picks up the new config.
      system.activationScripts.deploySigningKey = ''
        if [ ! -e ${secretKeyFile} ]; then
          mkdir -p /etc/nix
          (
            umask 077
            ${config.nix.package}/bin/nix-store --generate-binary-cache-key \
              ${signingKeyName} ${secretKeyFile} ${publicKeyFile}
          )
          chmod 644 ${publicKeyFile}
          echo "Generated deploy signing key: $(cat ${publicKeyFile})"
        fi
      '';
    })

    (lib.mkIf cfg.target.enable {
      nix.settings.trusted-public-keys = cfg.target.trustedPublicKeys;
    })
  ];
}
