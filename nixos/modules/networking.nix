deviceName: userName:
{ config, pkgs, lib, ... }:

let
  cfg = config.custom.networking;
  hostname = cfg.hostname;
  nfsSupport = cfg.nfsSupport;
  wifiSupport = cfg.wifiSupport;
  withNetworkManager = cfg.withNetworkManager;
  myTools = pkgs.myTools { osConfig = config; };
  openvpnClient = cfg.openvpn.client.enable;
  openvpnAutoConnect = cfg.openvpn.client.autoConnect;
in {
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
        Whether to add WiFi support with a collection of WAPs.
      '';
    };
    withNetworkManager = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable NetworkManager for Ethernet, WWAN, VPN, etc..
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

    # Enables wireless support via wpa_supplicant.
    networking.wireless.enable = true && wifiSupport;
    # Allow changes with wpa_gui & wpa_cli
    networking.wireless.userControlled.enable = true;
    # Allow coexistence of declaratively & imeratively network configs!
    networking.wireless.allowAuxiliaryImperativeNetworks = true;

    # Device specific wireless network adapters, should be listed in their corresponding conf file!
    #networking.wireless.interfaces = [
    #];

    # Endpoints to use with wpa_supplicant
    # WARNING: Be aware that keys will be written to the nix store in plaintext!
    #          When no netwokrs are set it will default to using a configuration file at /etc/wpa_supplicant.conf
    networking.wireless.networks = myTools.getSecret ../. "waps.nix";

    networking.networkmanager.enable = wifiSupport && withNetworkManager;
    # WWAN FCC unlocking
    networking.networkmanager.enableFccUnlock = wifiSupport && withNetworkManager;
    # NOTE: networking.networkmanager and networking.wireless (WPA Supplicant) can be used together if desired.
    #       To do this you need to instruct NetworkManager to ignore those interfaces like:
    networking.networkmanager.unmanaged = [
      "*" "except:type:ethernet" "except:type:wwan" "except:type:gsm"
    ];
    # nixos-rebuild fails somtimes... See: https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

    # VPNs
    services.openvpn.servers = lib.mkIf openvpnClient {
      homeVPN = {
        config = ''config /home/${userName}/vpns/homeVPN.ovpn''; # The content of the config file can be pasted here too!
        autoStart = openvpnAutoConnect;
        updateResolvConf = true;
      };
    };

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networking.firewall = let 
      portDefSet = (myTools.getSecret ../. "usedPorts.nix") myTools;
    in {
      # Open ports in the firewall.
      allowedTCPPorts = myTools.getAllExposedTCPports portDefSet;
      allowedUDPPorts = myTools.getAllExposedUDPports portDefSet;
      # Or disable the firewall altogether.
      enable = true;
    };

    # network debugging
    programs.wireshark.enable = true;
    users.users."${userName}".extraGroups = lib.optional config.programs.wireshark.enable
      "wireshark"
    ;
  };
}

