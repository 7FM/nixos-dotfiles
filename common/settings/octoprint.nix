{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  myTools = pkgs.myTools { osConfig = config; };
  myPorts = (myTools.getSecret ../../nixos "usedPorts.nix") myTools;

  myMiscSecrets = (myTools.getSecret ../../nixos "misc.nix");

  zigbee2mqttFrontendPort = myTools.extractPort myPorts.zigbee2mqtt "frontend";
  mqttPort = myTools.extractPort myPorts.mosquitto "mqtt";
  hassInternalPort = myTools.extractPort myPorts.homeassistant "internal";
  hassProxyPort = myTools.extractPort myPorts.homeassistant "proxy";
  mqttUser = myMiscSecrets.mqtt.user;
  mqttPwd = myMiscSecrets.mqtt.pwd;

  localStaticIP = myMiscSecrets.localStaticIP;
in
lib.mkMerge [
  {
    custom = {
      # System settings
      gpu = "generic";
      cpu = "generic";
      gui.headless = true;
      useDummySecrets = false;
      bluetooth = false;
      audio.backend = "none";
      # Homemanager settings
      hm = {
        modules = {
          alacritty.enable = false;
          bash.enable = true;
          calendar.enable = false;
          easyeffects.enable = false;
          email.enable = false;
          git = {
            enable = true;
            identity_scripts.enable = false;
          };
          gtk.enable = false;
          neovim.enable = true;
          optimize_storage.enable = true;
          qt.enable = false;
          ssh.enable = false;
          xdg.enable = true;
          zsh.enable = true;
        };
        collections = {
          communication.enable = false;
          development.enable = false;
          diyStuff.enable = false;
          gaming.enable = false;
          gui_utilities.enable = false;
          media.enable = false;
          office.enable = false;
          utilities.enable = true;
        };
      };
    };
  }
  {
    # File systems configuration for using the installer's partition layout
    fileSystems = {
      # Prior to 19.09, the boot partition was hosted on the smaller first partition
      # Starting with 19.09, the /boot folder is on the main bigger partition.
      # The following is to be used only with older images.
      /*
        "/boot" = {
          device = "/dev/disk/by-label/NIXOS_BOOT";
          fsType = "vfat";
        };
      */
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
    };

    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = 4 * 1024;
      }
    ];

    hardware.raspberry-pi."4" = {
      audio.enable = false;
      dwc2 = {
        enable = false;
      };
      i2c0.enable = false;
      i2c1.enable = false;
      poe-hat.enable = false;
      pwm0.enable = false;
      tc358743.enable = false;
      fkms-3d = {
        enable = false;
      };
    };

    custom.grub = {
      enable = false;
      #useUEFI = false;
    };
    custom.cpuFreqGovernor = "ondemand";
    custom.laptopPowerSaving = false;
    custom.enableVirtualisation = false;
    custom.smartcards = false;
    custom.nano_conf.enable = true;
    custom.networking = {
      nfsSupport = false;
      wifiSupport = false;
      openvpn.client = {
        enable = false;
        autoConnect = false;
      };
    };
    custom.security = {
      gnupg.enable = false;
      usbguard = {
        enforceRules = false;
        #fixedRules = myTools.getSecret ../../nixos "usbguard-rules.nix";
      };
    };
    custom.internationalization = {
      defaultLcTime = "de_DE.UTF-8";
      defaultLcPaper = "de_DE.UTF-8";
      defaultLcMeasurement = "de_DE.UTF-8";
    };

    custom.sshServer = {
      enable = true;
    };

    networking.interfaces.eth0.useDHCP = true;

    # Disable the dhcp client for our AP interface!
    #networking.interfaces.wlan0.useDHCP = true;
    #networking.wireless.interfaces = [
    #  "wlan0"
    #];

    # Server certificate: self signed
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "who@car.ez";
        server = null;
      };
    };

    # Nginx Proxy
    services.nginx = {
      enable = true;
      serverTokens = false;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts =
        let
          nginxSecurityHeaders = ''
            add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
            add_header Referrer-Policy "no-referrer" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-Download-Options "noopen" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Permitted-Cross-Domain-Policies "none" always;
            add_header X-Robots-Tag "none" always;
            add_header X-XSS-Protection "1; mode=block" always;
            fastcgi_hide_header X-Powered-By;
            ## Block some robots ##
            if ($http_user_agent ~* msnbot|scrapbot) {
                return 403;
            }
            ## Block download agents ##
            if ($http_user_agent ~* LWP::Simple|BBBike|wget) {
                return 403;
            }
          '';

          defaultConf = extraConf: {
            # forceSSL = true;
            onlySSL = true;
            useACMEHost = localStaticIP;
            serverName = localStaticIP;
            extraConfig = ''
              ${nginxSecurityHeaders}
              # ignore_invalid_headers off;
              ${extraConf}
            '';
            http2 = true;
            kTLS = true;
          };

          defaultLocations = {
            "/favicon.ico" = {
              extraConfig = "log_not_found off;";
            };
          };

          createListenEntriesOptSSL = myPort: ssl: [
            {
              addr = "0.0.0.0";
              port = myPort;
              inherit ssl;
            }
            {
              addr = "[::]";
              port = myPort;
              inherit ssl;
            }
          ];

          createListenEntries = myPort: createListenEntriesOptSSL myPort true;

        in
        {
          acme = (defaultConf "") // {
            enableACME = true;
            useACMEHost = null;
          };

          hass = (defaultConf "") // {
            listen = createListenEntries hassProxyPort;
            locations = defaultLocations // {
              "/" = {
                proxyPass = "http://localhost:${toString hassInternalPort}/";
                extraConfig = ''
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection $connection_upgrade;
                  proxy_http_version 1.1;
                '';
              };
            };
          };
        };
    };

    services.mosquitto = {
      enable = true;
      # Helpful to debug whether publish requests etc. were denied
      # logType = [ "all" ];
      listeners = [
        {
          port = mqttPort;
          address = "127.0.0.1";
          users = {
            "${mqttUser}" = {
              password = mqttPwd;
              acl = [
                "readwrite homeassistant/#"
                "readwrite zigbee2mqtt/#"
              ];
            };
          };
        }
      ];
    };

    services.zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant = {
          enabled = config.services.home-assistant.enable;
          discovery_topic = "homeassistant";
          status_topic = "homeassistant/status";
        };
        permit_join = true;
        frontend = {
          enable = false;
          port = zigbee2mqttFrontendPort;
        };
        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtt://localhost:${toString mqttPort}";
          user = mqttUser;
          password = mqttPwd;
        };
        serial = {
          adapter = "deconz";
          port = "/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2669275-if00";
        };
        advanced = {
          log_output = [ "console" ];
          network_key = myMiscSecrets.zigbee2mqtt.network_key;
        };
        devices = myMiscSecrets.zigbee2mqtt.devices;
      };
    };

    services.home-assistant = {
      enable = true;
      extraComponents = [
        "default_config"
        "met"
        "mqtt"
        "kodi"
        "sun"
      ];
      config = {
        http = {
          server_port = hassInternalPort;
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];
        };
        homeassistant.unit_system = "metric";
        frontend.themes = "!include_dir_merge_named themes";
        automation = "!include automations.yaml";
        script = "!include scripts.yaml";
        scene = "!include scenes.yaml";
      };
    };

  }
  (import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
