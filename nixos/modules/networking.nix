deviceName: userName:
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.custom.networking;
  hostname = cfg.hostname;
  nfsSupport = cfg.nfsSupport;
  wifiSupport = cfg.wifiSupport;
  myTools = pkgs.myTools { osConfig = config; };
  openvpnClient = cfg.openvpn.client.enable;
  openvpnAutoConnect = cfg.openvpn.client.autoConnect;
in
{
  options.custom.networking = with lib; {
    nfsSupport = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to add support to mount NFS.
      '';
    };
    wifiSupport = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to add WiFi support via NetworkManager.
      '';
    };
    hostname = mkOption {
      type = types.str;
      default = "nixos-" + deviceName;
      description = ''
        Specifies the hostname of this system.
      '';
    };

    openvpn.client = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Install openvpn and create a default config to connect to a home vpn.
        '';
      };
      autoConnect = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Auto connect with the home vpn.
        '';
      };
    };
  };

  config = {
    networking.hostName = hostname;

    services.rpcbind.enable = lib.mkDefault nfsSupport;
    boot.supportedFilesystems = lib.optionals nfsSupport [ "nfs" ];

    # NM uses wpa_supplicant as its WiFi backend — stays true whenever WiFi is wanted.
    networking.wireless.enable = wifiSupport;

    networking.networkmanager.enable = wifiSupport;
    # NM manages WiFi when wifiSupport is on; otherwise only ethernet/wwan/gsm.
    networking.networkmanager.unmanaged =
      [
        "*"
        "except:type:ethernet"
        "except:type:wwan"
        "except:type:gsm"
      ]
      ++ lib.optional wifiSupport "except:type:wifi";
    # nixos-rebuild fails sometimes... See: https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

    # VPNs
    services.openvpn.servers = lib.mkIf openvpnClient {
      homeVPN = {
        config = "config /home/${userName}/vpns/homeVPN.ovpn"; # The content of the config file can be pasted here too!
        autoStart = openvpnAutoConnect;
        updateResolvConf = true;
      };
      workVPN = {
        config = ''
          config /home/${userName}/vpns/workVPN.ovpn
        ''; # The content of the config file can be pasted here too!
        autoStart = false;
        updateResolvConf = true;
      };
    };

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;

    networking.firewall =
      let
        portDefSet = (myTools.getSecret ../. "usedPorts.nix") myTools;
      in
      {
        # Open ports in the firewall.
        allowedTCPPorts = myTools.getAllLocallyExposedTCPports portDefSet;
        allowedUDPPorts = myTools.getAllLocallyExposedUDPports portDefSet;
        # Or disable the firewall altogether.
        enable = true;
      };

    # network debugging
    programs.wireshark.enable = true;
    users.users."${userName}".extraGroups = lib.optional config.programs.wireshark.enable "wireshark";
  };
}
