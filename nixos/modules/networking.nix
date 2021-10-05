{ config, pkgs, lib, ... }:

{
  networking.hostName = config.custom.hostname;

  # Enables wireless support via wpa_supplicant.
  networking.wireless.enable = true;
  # Allow changes with wpa_gui & wpa_cli
  networking.wireless.userControlled.enable = true;
  # Device specific wireless network adapters, should be listed in their corresponding conf file!
  #networking.wireless.interfaces = [
  #];

  networking.networkmanager.enable = true;
  # NOTE: networking.networkmanager and networking.wireless (WPA Supplicant) can be used together if desired.
  #       To do this you need to instruct NetworkManager to ignore those interfaces like:
  networking.networkmanager.unmanaged = [
    "*" "except:type:wwan" "except:type:gsm"
  ];
  # NetworkManager plugins
  networking.networkmanager.packages = with pkgs; [
    networkmanager_openvpn
    networkmanager_openconnect
  ];

  # Endpoints to use with wpa_supplicant
  # WARNING: Be aware that keys will be written to the nix store in plaintext!
  #          When no netwokrs are set it will default to using a configuration file at /etc/wpa_supplicant.conf
  networking.wireless.networks = import ../secrets/waps.nix;

  # VPNs
  services.openvpn.servers = {
    #homeVPN = {
    #  config = ''config /home/tm/vpns/homeVPN.conf''; # The content of the config file can be pasted here too!
    #  autoStart = true;
    #  updateResolvConf = true;
    #};
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = import ../secrets/allowedTCPPorts.nix;
  networking.firewall.allowedUDPPorts = import ../secrets/allowedUDPPorts.nix;
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # network debugging
  programs.wireshark.enable = true;
  users.users.tm.extraGroups = [
    "wireshark"
  ];

}

