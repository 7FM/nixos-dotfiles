{
  config,
  lib,
  ...
}:

let
  cfg = config.custom.wifiHotspot;
in
{
  options.custom.wifiHotspot = with lib; {
    enable = mkEnableOption "WiFi hotspot";

    upstreamInterface = mkOption {
      type = types.str;
      description = ''
        The WiFi interface to share internet from (e.g. "wlp0s20f3").
        Must support concurrent client+AP operation.
      '';
    };

    apInterface = mkOption {
      type = types.str;
      default = "wlan1";
      description = ''
        Name for the virtual AP interface to create on top of upstreamInterface.
      '';
    };

    gatewayIp = mkOption {
      type = types.str;
      default = "192.168.50.1";
      description = ''
        IP address assigned to the hotspot gateway (/24 subnet assumed).
      '';
    };

    band = mkOption {
      type = types.enum [ "2g" "5g" ];
      default = "5g";
      description = ''
        WiFi band to use for the hotspot.
      '';
    };

    channel = mkOption {
      type = types.int;
      default = 0;
      description = ''
        WiFi channel. 0 enables automatic channel selection (ACS) if the
        driver supports it. Otherwise pick one valid for the chosen band
        (e.g. 6 for 2.4 GHz, 36/149/153 for 5 GHz).
      '';
    };

    ssid = mkOption {
      type = types.str;
      description = "SSID (network name) for the hotspot.";
    };

    wpaPassword = mkOption {
      type = types.str;
      description = "WPA2-SHA256 password for the hotspot.";
    };
  };

  config =
    let
      apIf = cfg.apInterface;
      upstreamIf = cfg.upstreamInterface;
      gwIp = cfg.gatewayIp;
      subnetPrefix = lib.concatStringsSep "." (lib.take 3 (lib.splitString "." gwIp));
      apDeviceUnit = "sys-subsystem-net-devices-${apIf}.device";
    in
    lib.mkIf cfg.enable {
      # Declare both interfaces explicitly. Once a physical device appears in
      # wlanInterfaces, NixOS no longer auto-creates its default udev interface,
      # so the upstream station interface must be re-declared here too.
      networking.wlanInterfaces = {
        ${upstreamIf} = { device = upstreamIf; };
        ${apIf}       = { device = upstreamIf; };
      };

      networking = {
        nat = {
          enable = true;
          externalInterface = upstreamIf;
          internalInterfaces = [ apIf ];
        };

        interfaces.${apIf}.ipv4.addresses = [
          {
            address = gwIp;
            prefixLength = 24;
          }
        ];

        firewall.interfaces.${apIf} = {
          allowedUDPPorts = [ 53 67 ];
          allowedTCPPorts = [ 53 ];
        };

        # Prevent NM from managing the AP interface if it's running
        networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [
          "interface-name:${apIf}"
        ];
      };

      systemd.services.hostapd = {
        requires = [ apDeviceUnit ];
        after = [ apDeviceUnit ];
      };

      systemd.services.dnsmasq = {
        requires = [ apDeviceUnit ];
        after = [ apDeviceUnit ];
      };

      services.hostapd = {
        enable = true;
        radios.${apIf} = {
          band = cfg.band;
          channel = cfg.channel;
          wifi4.enable = true;
          networks.${apIf} = {
            ssid = cfg.ssid;
            authentication = {
              mode = "wpa2-sha256";
              wpaPassword = cfg.wpaPassword;
            };
          };
        };
      };

      services.dnsmasq = {
        enable = true;
        settings = {
          interface = apIf;
          bind-interfaces = true;
          dhcp-range = "${subnetPrefix}.10,${subnetPrefix}.100,12h";
        };
      };
    };
}
