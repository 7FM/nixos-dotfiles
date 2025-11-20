{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  myPorts = (myTools.getSecret ../../nixos "usedPorts.nix") myTools;

  myOpencloudSecrets = (myTools.getSecret ../../nixos "opencloud.nix");
  myLetsEncryptSecrets = (myTools.getSecret ../../nixos "letsencrypt.nix");
  myRadicaleSecrets = (myTools.getSecret ../../nixos "radicale.nix");
  myMiscSecrets = (myTools.getSecret ../../nixos "misc.nix");

  letsEncryptHost = myLetsEncryptSecrets.letsEncryptHost;
  letsEncryptEmail = myLetsEncryptSecrets.letsEncryptEmail;
  nginxTmpPath = "/var/lib/nginx_temp_path";
  opencloudInitialAdminPwd = myOpencloudSecrets.opencloudInitialAdminPwd;
  opencloudStateDir = myOpencloudSecrets.opencloudStateDir;

  radicaleMntPoint = myMiscSecrets.radicaleMntPoint;
  downloadRoot = myMiscSecrets.downloadRoot;
  giteaAppName = myMiscSecrets.giteaAppName;

  # Exposed ports
  radicaleProxyPort = myTools.extractPort myPorts.radicale "proxy";
  radicaleInternalPort = myTools.extractPort myPorts.radicale "internal";
  downloadPort = myTools.extractPort myPorts.downloadPage "";
  giteaPort = myTools.extractPort myPorts.gitea "proxy";
  opencloudPort = myTools.extractPort myPorts.opencloud "proxy";
  jellyfinPort = myTools.extractPort myPorts.jellyfin "proxy";
  jellyfinInternalHttpPort = myTools.extractPort myPorts.jellyfin "http";
  nfsPortmapperPort = myTools.extractPort myPorts.nfs "portmapper";
  nfsNfsdPort = myTools.extractPort myPorts.nfs "nfsd";
  openvpnServerPort = myTools.extractPort myPorts.openvpn_server "";
  # Hidden internal ports
  giteaInternalPort = myTools.extractPort myPorts.gitea "internal";
  opencloudInternalPort = myTools.extractPort myPorts.opencloud "opencloudInternal";
  syncthingHttpPort = myTools.extractPort myPorts.syncthing "";

  # OpenVPN config
  vpn-dev = "tun0";
  eth-dev = "enp1s0";
  openvpn_dns_server = "192.168.0.1";
  commonConf = ''
      port ${toString openvpnServerPort}

      auth-nocache

      comp-lzo
      keepalive 10 60
      persist-key
      persist-tun
  '';
  openvpn_dh = "/root/openvpn/dh.pem";
  openvpn_ca = "/root/openvpn/ca.crt";
  openvpn_server_cert = "/root/openvpn/tmserver.crt";
  openvpn_server_key = "/root/openvpn/tmserver.key";
  openvpn_server_conf = ''
      dev ${vpn-dev}
      proto udp
      proto udp6
      server 10.8.0.0 255.255.255.0
      push "dhcp-option DNS ${openvpn_dns_server}"
      max-clients 3
      # Notify the client that when the server restarts so it
      # can automatically reconnect.
      explicit-exit-notify 1
      ${commonConf}
      ping-timer-rem
      dh ${openvpn_dh}
      ca ${openvpn_ca}
      cert ${openvpn_server_cert}
      key ${openvpn_server_key}
  '';

  # Example openvpn client config:
  openvpn_example_client_etc_path = "openvpn/nixos-client-example.ovpn";
  openvpn_example_client_conf = ''
      client
      dev tun
      remote "${letsEncryptHost}"
      ${commonConf}

      redirect-gateway def1
      resolv-retry infinite
      nobind
      # Verify server certificate
      remote-cert-tls server
      dhcp-option DNS ${openvpn_dns_server}

      ca [inline]
      cert [inline]
      key [inline]

      # TODO copy & paste your .inline file here!
  '';

  # List of datasets to exclude from ZFS backups
  zfsBackupBlacklistedDatasets = [ "vault/nginx_temp_path" "vault/html" ];
in lib.mkMerge [
{
  custom = {
    # System settings
    gpu = "generic";
    cpu = "generic";
    gui = "headless";
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
          identity_scripts.enable = true;
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
  swapDevices = [ { device = "/dev/disk/by-uuid/0336bfa3-bb49-4bb5-be01-d03564e897d9"; } ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/41607c2e-6b3e-4841-8a93-676d30bdced5";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/48D3-8954";
      fsType = "vfat";
    };

    "/var/lib/nfs_data" = {
      device = "vault/nfs_data";
      fsType = "zfs";
    };
    "${config.services.gitea.stateDir}" = {
      device = "vault/gitea";
      fsType = "zfs";
    };
    "/var/www/html" = {
      device = "vault/html";
      fsType = "zfs";
    };
    "${radicaleMntPoint}" = {
      device = "vault/radicale";
      fsType = "zfs";
    };
    "/var/lib/syncthing" = {
      device = "vault/syncthing";
      fsType = "zfs";
    };
    "/var/lib/jellyfin" = {
      device = "vault/jellyfin";
      fsType = "zfs";
    };
    "${nginxTmpPath}" = {
      device = "vault/nginx_temp_path";
      fsType = "zfs";
    };
    "${config.services.opencloud.stateDir}" = {
      device = "vault/opencloud";
      fsType = "zfs";
    };
  };

  # MAIN POOL
  # sudo zpool create -O encryption=on -O keyformat=raw -O keylocation=file:///root/zfs.key -O compression=on -O mountpoint=legacy -O xattr=sa -O atime=off -O acltype=posixacl -o ashift=12 vault raidz2 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1 /dev/nvme5n1
  # sudo zpool import vault
  # sudo zfs load-key -a

  # BACKUP POOL
  # sudo zpool create -O compression=on -O mountpoint=legacy -O xattr=sa -O atime=off -O acltype=posixacl -o ashift=12 vault_backup /dev/sda /dev/sdb /dev/sdd
  # sudo zpool import vault_backup


  # Trying to mitigate nvme connection losses
  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
    "pcie_port_pm=off"
  ];

  # Force Lexar NM790 NVME SSDs into power state 2 -> 3.6W each!
  # Systemd service to force PS2 on all NVMe drives
  systemd.services."nvme-ps2" = {
    description = "Force NVMe drives into PS2";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/bin/sh -c 'for dev in /dev/nvme[0-9]; do ${pkgs.nvme-cli}/bin/nvme set-feature \"$dev\" --feature-id=2 --value=2; done'";
    };
  };

  # Enable zfs
  boot.supportedFilesystems.zfs = true;
  boot.initrd.supportedFilesystems.zfs = true;
  boot.zfs.extraPools = [ "vault" ];
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
    zed.settings = {
      ZED_EMAIL = "who@carez.cum";
      ZED_EMAIL_PROG = "/home/tm/zed_telegram_notify.sh";

      ZED_NOTIFY_VERBOSE = true; # TODO set to false
      # ZED_DEBUG_LOG = "/tmp/zed.debug.log";

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = false;
    };
  };
  networking.hostId = "2c82493e"; # Not sure why ZFS requires a value for this

  # Automatically creata and manage zfs backup snapshots!
  services.sanoid = {
    enable = true;

    # Define reusable templates
    templates = {
      "daily14keepMonthly" = {
        autosnap = true;
        autoprune = true;

        # Retention policy
        hourly = 0;        # no hourly snapshots
        daily = 14;        # keep 14 days
        weekly = 0;        # no weeklies
        monthly = 1;       # keep 1 monthly
      };
    };

    # Apply template to all mounted dataset
    datasets = let
      # Filter ZFS mounts, exclude blacklisted
      zfsDatasets = lib.attrsets.filterAttrs
        (_: fs: fs.fsType == "zfs" && fs.device != null && !(lib.elem fs.device zfsBackupBlacklistedDatasets))
        config.fileSystems;

      # Extract dataset names from .device
      datasetNames = builtins.attrValues (lib.attrsets.mapAttrs'
        (_: fs: lib.nameValuePair fs.device fs.device)
        zfsDatasets);
    in lib.genAttrs datasetNames (_: {
      useTemplate = [ "daily14keepMonthly" ];
    });
  };

  # Setup local/remote backups
  # TODO change to off-site backups!
  services.syncoid = {
    enable = true;
    # common arguments applied to all commands
    commonArgs = [
      "--delete-target-snapshots"
      "--skip-parent"
      "--no-sync-snap" # Do not create your own snapshots
    ];

    # interval for all jobs (systemd timer)
    interval = "weekly";  # runs once per week

    commands = {
      "vault-to-vault_backup" = {
        useCommonArgs = true;
        source = "vault";       # your encrypted source pool
        target = "vault_backup";# your backup pool (can be unencrypted)
        recursive = true;
        sendOptions = "raw"; # For encrypted mirroring
        extraArgs = map (ds: "--exclude-datasets=" + ds) zfsBackupBlacklistedDatasets; # Prevent backing up the blacklisted datasets
      };
    };
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  hardware.cpu.intel.updateMicrocode = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  custom = {
    grub = {
      enable = false;
      #useUEFI = false;
    };
    cpuFreqGovernor = "ondemand";
    laptopPowerSaving = false;
    enableVirtualisation = false;
    smartcards = false;
    nano_conf.enable = true;
    networking = {
      nfsSupport = false;
      wifiSupport = false;
      withNetworkManager = false;
      openvpn.client = {
        enable = false;
        autoConnect = false;
      };
    };
    security = {
      gnupg.enable = false;
      usbguard = {
        enforceRules = true;
        fixedRules = myTools.getSecret ../../nixos "usbguard-rules.nix";
      };
    };
    internationalization = {
      defaultLcTime = "de_DE.UTF-8";
      defaultLcPaper = "de_DE.UTF-8";
      defaultLcMeasurement = "de_DE.UTF-8";
    };

    sshServer = {
      enable = true;
    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;
  networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;

  # TODO script + timer to fetch github and update the system!
  # TODO this might be of interest: https://nixos.wiki/wiki/Automatic_system_upgrades

  # Server configuration
  systemd.timers."force-hdd-to-sleep" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30m";
      OnUnitActiveSec = "30m";
      Unit = "force-hdd-to-sleep.service";
    };
  };

  systemd.services."force-hdd-to-sleep" = {
    script = ''
      # This script looks for recent disk access, and if nothing has changed, puts /dev/"drive" into spindown mode.
      # This should be used only if the hdparm power management function is not working.
      # Call this script with cron or manually as desired
      #
      #
      #
      # Change which drive this script looks at by changing the drive variable below:
      # Currently it will apply the force standby to all drives available
      drives=`${pkgs.util-linux}/bin/lsblk`
      #
      #

      ${pkgs.coreutils}/bin/echo "$drives" | ${pkgs.gnugrep}/bin/grep part | ${pkgs.gnugrep}/bin/grep -oP "sd[a-z]" | ${pkgs.coreutils}/bin/uniq | while read drive ; do

          # Each drive has its own log file to store the latest drive access time from a previous script call
          filename="/tmp/diskaccess-''${drive}.txt"
          sleep_filename="/tmp/diskaccess-''${drive}_sleep.txt"
          stat_new=`${pkgs.coreutils}/bin/cat /sys/block/"$drive"/stat | ${pkgs.coreutils}/bin/tr -dc "[:digit:]"`

          # Check if the log file exists
          if [ -f "$filename" ]; then
              # Get the latest access time
              stat_old=`${pkgs.coreutils}/bin/cat "$filename" | ${pkgs.coreutils}/bin/tr -dc "[:digit:]"`

              # Check if the drive was accessed
              if [ "$stat_old" = "$stat_new" ]; then
                  # Drive was not used since last call
                  # Lets send a standby command
                  # But only once, else this might trigger some useless hdd spin ups!
                  if [ ! -f "$sleep_filename" ]; then
                      ${pkgs.hdparm}/bin/hdparm -y /dev/"$drive" > /dev/null 2>&1
                      # Create the sleep file to indicate that the drive was already set to sleep!
                      ${pkgs.coreutils}/bin/touch "$sleep_filename"
                  fi
              else
                  # Drive was used since last time the script got executed
                  # Update the last access time
                  ${pkgs.coreutils}/bin/echo "$stat_new" > "$filename"
                  # Drive is no longer in sleep mode, ensure to delete this state file it!
                  ${pkgs.coreutils}/bin/rm -f "$sleep_filename"
              fi
          else
              # File does not exist so lets create it
              ${pkgs.coreutils}/bin/echo "$stat_new" > "$filename"
              # Drive is no longer in sleep mode, ensure to delete this state file it!
              ${pkgs.coreutils}/bin/rm -f "$sleep_filename"
          fi
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Server certificate: Let's Encrypt!
  security.acme = {
    acceptTerms = true;
    defaults.email = letsEncryptEmail;
  };
  systemd.services."acme-${letsEncryptHost}" = let
    port = myTools.extractPort myPorts.letsEncryptCertRenewal "";
  in {
    # NOTE: preStart and postStop were replaced by explicit ExecStartPre and ExecStopPort to run this as root user
    # preStart = ''
    # postStop = ''
    serviceConfig = {
      # Automatically open the firewall port
      # Prefixed with a '+' to run as root!
      ExecStartPre = "+" + (pkgs.writeShellScript "acme-${letsEncryptHost}-pre-start" ''
          ${pkgs.iptables}/bin/iptables -I INPUT -p tcp --dport ${toString port} -j ACCEPT || true
          ${pkgs.iptables}/bin/ip6tables -I INPUT -p tcp --dport ${toString port} -j ACCEPT || true
      '');
      # Automatically close the firewall port again!
      # Prefixed with a '+' to run as root!
      ExecStopPost = "+" + (pkgs.writeShellScript "acme-${letsEncryptHost}-post-stop" ''
          ${pkgs.iptables}/bin/iptables -D INPUT -p tcp --dport ${toString port} -j ACCEPT || true
          ${pkgs.iptables}/bin/ip6tables -D INPUT -p tcp --dport ${toString port} -j ACCEPT || true
      '');
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

    virtualHosts = let
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

      defaultConf = extraConf : {
        # forceSSL = true;
        onlySSL = true;
        useACMEHost = letsEncryptHost;
        serverName = letsEncryptHost;
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

      createListenEntries = myPort: [
        {
          addr = "0.0.0.0";
          port = myPort;
          ssl = true;
        }
        {
          addr = "[::]";
          port = myPort;
          ssl = true;
        }
      ];

    in {
      "${letsEncryptHost}" = {
        forceSSL = true;
        enableACME = true;
      };

      radicale = (defaultConf "") // {
        listen = createListenEntries radicaleProxyPort;
        locations = defaultLocations // {
          "/" = {
            proxyPass = "http://localhost:${toString radicaleInternalPort}/";
            extraConfig = ''
              sendfile off;
              proxy_set_header  X-Script-Name /;
              proxy_pass_header Authorization;
            '';
          };
        };
      };

      download = (defaultConf ''
          ## Only allow these request methods ##
          if ($request_method !~ ^(GET)$ ) {
              return 403;
          }
        '') // {
        root = downloadRoot;
        basicAuthFile = "${downloadRoot}/.htpasswd";
        listen = createListenEntries downloadPort;
        locations = defaultLocations // {
          "/robots.txt" = {
            extraConfig = ''
              allow all;
              log_not_found off;
              access_log off;
            '';
          };
          "/" = {
            extraConfig = ''
              autoindex on;
            '';
          };
        };
      };

      gitea = (defaultConf ''
        ## Only allow these request methods ##
        ## PUT is required for LFS uploads ##
        if ($request_method !~ ^(GET|HEAD|POST|PUT)$ ) {
            return 403;
        }
        ## Do not accept DELETE, SEARCH and other methods ##
      '') // {
        listen = createListenEntries giteaPort;
        locations = defaultLocations // {
          "/" = {
            proxyPass = "http://localhost:${toString config.services.gitea.settings.server.HTTP_PORT}/";
            extraConfig = ''
              proxy_max_temp_file_size 0;
              proxy_connect_timeout      90s;
              proxy_send_timeout         90s;
              proxy_read_timeout         90s;
              proxy_redirect default;
            '';
          };
        };
      };

      opencloud = (defaultConf "") // {
        listen = createListenEntries opencloudPort;
        locations = defaultLocations // {
          "/" = {
            recommendedProxySettings = false;
            proxyWebsockets = true;
            proxyPass = "http://localhost:${toString config.services.opencloud.port}/";
            extraConfig = ''
              proxy_set_header Host $host:$server_port;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Scheme $scheme;
              proxy_connect_timeout   3600s;
              proxy_send_timeout      3600s;
              proxy_read_timeout      3600s;

              client_max_body_size 0;
              client_body_temp_path ${nginxTmpPath};
              proxy_temp_path ${nginxTmpPath};
            '';
          };
        };
      };

      jellyfin = (defaultConf "") // {
        listen = createListenEntries jellyfinPort;
        locations = defaultLocations // {
          "/" = {
            proxyPass = "http://localhost:${toString jellyfinInternalHttpPort}";
            extraConfig = ''
              proxy_pass_request_headers on;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection $http_connection;

              # Disable buffering when the nginx proxy gets very resource heavy upon streaming
              proxy_buffering off;
            '';
          };
        };
      };
    };
  };
  # Allow access to body temp path
  systemd.services.nginx.serviceConfig.ReadWritePaths = [
    nginxTmpPath
  ];

  # Calendar + Contact Server: Radicale
  services.radicale = {
    enable = true;
    settings = {
      storage.filesystem_folder = "${radicaleMntPoint}/collections";
      auth = {
        type = "htpasswd";
        htpasswd_filename = "${radicaleMntPoint}/users";
        htpasswd_encryption = "bcrypt";
        delay = 5;
      };
    };
  };

  services.opencloud = {
    enable = true;
    port = opencloudInternalPort;
    stateDir = opencloudStateDir;
    url = "https://${letsEncryptHost}:${toString opencloudPort}";
    environment = {
      IDM_ADMIN_PASSWORD = opencloudInitialAdminPwd;
      IDM_CREATE_DEMO_USERS = "false";
      PROXY_TLS = "false"; # No encryption between opencloud and the reverse proxy
      # INSECURE: needed if OpenCloud / reverse proxy is using self generated certificates
      OC_INSECURE = "false";
      # OC_LOG_LEVEL = "error";
      # basic auth (not recommended, but needed for eg. WebDav clients that do not support OpenID Connect)
      PROXY_ENABLE_BASIC_AUTH = "false";
      PROXY_INSECURE_BACKENDS = "true"; # Disable TLS certificate validation for all HTTP backend connections
    };
    # settings = {
    # };
  };

  # Git server:
  services.gitea = {
    enable = true;
    appName = giteaAppName;
    database = {
      type = "sqlite3";
      createDatabase = false;
    };
    lfs.enable = true;
    settings = {
      server = rec {
        SSH_PORT = (builtins.elemAt config.services.openssh.ports 0);
        HTTP_ADDR = "127.0.0.1";
        DOMAIN = letsEncryptHost;
        SSH_DOMAIN = DOMAIN;
        HTTP_PORT = giteaInternalPort;
        ROOT_URL = "https://${DOMAIN}:${toString giteaPort}/";
        DISABLE_SSH = false;
        LFS_START_SERVER = true;
        LFS_HTTP_AUTH_EXPIRY = "20m";
        LFS_MAX_FILE_SIZE = 0;
        LFS_LOCKS_PAGING_NUM = 50;
        OFFLINE_MODE = true;
        START_SSH_SERVER = false;
      };
      service = {
        REGISTER_EMAIL_CONFIRM = false;
        ENABLE_NOTIFY_MAIL = false;
        DISABLE_REGISTRATION = true;
        ALLOW_ONLY_EXTERNAL_REGISTRATION = false;
        ENABLE_CAPTCHA = false;
        REQUIRE_SIGNIN_VIEW = true;
        DEFAULT_KEEP_EMAIL_PRIVATE = false;
        DEFAULT_ALLOW_CREATE_ORGANIZATION = false;
        DEFAULT_ENABLE_TIMETRACKING = true;
        NO_REPLY_ADDRESS = "noreply.example.org";
      };
      picture = {
        DISABLE_GRAVATAR = true;
        ENABLE_FEDERATED_AVATAR = false;
      };
      openid = {
        ENABLE_OPENID_SIGNIN = false;
        ENABLE_OPENID_SIGNUP = false;
      };
      session.PROVIDER = "file";
      api.ENABLE_SWAGGER = false;
      webhook.ALLOWED_HOST_LIST = "external, 127.0.0.1";
    };
  };

  services.jellyfin = {
    enable = true;
  };
  # services.jellyseerr = {
  #   enable = true;
  # };

  #TODO pihole?
  
  # Syncthing
  services.syncthing = {
    enable = true;
    systemService = true;
    openDefaultPorts = true;
    # guiAddress = "127.0.0.1:${toString syncthingHttpPort}";
    # TODO create HTTPS proxy
    guiAddress = "0.0.0.0:${toString syncthingHttpPort}";
    #TODO we could hardcode which devices & folders are allowed
  };

  # VPN server
  networking.nat = {
    enable = true;
    externalInterface = eth-dev;
    internalInterfaces  = [ vpn-dev ];
  };
  networking.firewall.trustedInterfaces = [ vpn-dev ];
  services.openvpn.servers.server = {
    config = openvpn_server_conf;
    autoStart = true;
  };
  environment.etc."${openvpn_example_client_etc_path}" = {
    text = openvpn_example_client_conf;
    mode = "600";
  };

  # DryNoMore Service
  # systemd.services."drynomore" = let 
  #     securityOptions = {
  #       ProtectHome = true;
  #       PrivateUsers = true;
  #       PrivateDevices = true;
  #       ProtectClock = true;
  #       ProtectHostname = true;
  #       ProtectProc = "invisible";
  #       ProtectKernelModules = true;
  #       ProtectKernelTunables = true;
  #       ProtectKernelLogs = true;
  #       ProtectControlGroups = true;
  #       RestrictNamespaces = true;
  #       LockPersonality = true;
  #       RestrictRealtime = true;
  #       RestrictSUIDSGID = true;
  #       MemoryDenyWriteExecute = true;
  #       SystemCallArchitectures = "native";
  #       RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" ];
  #     };
  # in {
  #   serviceConfig = securityOptions // {
  #     Type = "simple";
  #     User = "drynomore";
  #     Group = "drynomore";
  #     DynamicUser = true;
  #     StateDirectory = "drynomore";
  #     RuntimeDirectory = "drynomore";
  #     LogsDirectory = "drynomore";
  #     ConfigurationDirectory = "drynomore";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #   };
  #   script = "${pkgs.drynomore}/bin/drynomore-telegram-bot /var/lib/drynomore/config.yaml";
  #   wantedBy = [ "multi-user.target" ];
  # };
  systemd.services."tmdbot" = let
      securityOptions = {
        ProtectHome = true;
        PrivateUsers = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        RestrictAddressFamilies = [ ];
        # RestrictAddressFamilies = [ "AF_INET" ];
      };
  in {
    serviceConfig = securityOptions // {
      Type = "simple";
      User = "tmdbot";
      Group = "tmdbot";
      DynamicUser = true;
      StateDirectory = "tmdbot";
      RuntimeDirectory = "tmdbot";
      LogsDirectory = "tmdbot";
      ConfigurationDirectory = "tmdbot";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    script = "${pkgs.tmdbot}/bin/tmdbot /var/lib/tmdbot/settings.yaml /var/lib/tmdbot/user_data.yaml";
    wantedBy = [ "multi-user.target" ];
  };

  # Scripted DDNS & Router firewall updates
  systemd.timers."update-ddns" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30m";
      OnUnitActiveSec = "30m";
      Unit = "update-ddns.service";
    };
  };

  systemd.services."update-ddns" = let
    myPython = pkgs.python3;
    myPyPackages = python-packages: with python-packages; [
      (callPackage ../../custom_pkgs/compal.nix { })
    ];
    myPythonWithPackages = myPython.withPackages myPyPackages;

    update_router_forwards = let
      portDefSet = (myTools.getSecret ../../nixos "usedPorts.nix") myTools;
      exposedTCPPorts = myTools.getAllInternetExposedTCPports portDefSet;
      exposedUDPPorts = myTools.getAllInternetExposedUDPports portDefSet;
      createForwardRule = prot: ports: builtins.map 
        (p: "    IPv6FilterRule(dir=RuleDir.incoming, dst_addr=newIPv6Addr, dst_sport=${toString p}, dst_eport=${toString p}, protocol=IPv6FilterRuleProto.${prot})")
        ports;
      forwardRules = builtins.concatStringsSep ",\n" ((createForwardRule "tcp" exposedTCPPorts) ++ (createForwardRule "udp" exposedUDPPorts));
    in pkgs.writeText "update_router_forwards.py" ''
      from compal import *
      import sys

      if len(sys.argv) < 3:
        print("Missing argument: routerPwd ipAddr")
        sys.exit(1)

      routerPwd = sys.argv[1]
      newIPv6Addr = sys.argv[2]

      modem = Compal('192.168.0.1', routerPwd, False, True)
      modem.login()

      fw = Filters(modem)
      inRules, outRules = fw.delete_all_ipv6_filter_rules()

      newRules = [
      ${forwardRules}
      ]

      # Add the updated rules
      for rule in newRules:
          fw.set_ipv6_filter_rule(rule)

      # And logout
      modem.logout()
    '';

      securityOptions = {
        ProtectHome = true;
        PrivateUsers = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        # We need AF_NETLINK to obtain the ipv6 address
        RestrictAddressFamilies = [ "AF_NETLINK" "AF_UNIX" "AF_INET" "AF_INET6" ];
      };

    # Hardcoded due to DynamicUser
    update_ddns_root = "/var/lib/update_ddns";

  in {
    serviceConfig = securityOptions // {
      Type = "oneshot";
      User = "updateddns";
      Group = "updateddns";
      DynamicUser = true;
      StateDirectory = "update_ddns";
      RuntimeDirectory = "update_ddns";
      LogsDirectory = "update_ddns";
      ConfigurationDirectory = "update_ddns";
    };
    script = ''
#.Distributed under the terms of the GNU General Public License (GPL) version 2.0
#
# script for sending updates to no-ip.com / noip.com
#.2014-2015 Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
#
# This script is parsed by dynamic_dns_functions.sh inside send_update() function
#
# provider did not reactivate records, if no IP change was recognized
# so we send a dummy (localhost) and a seconds later we send the correct IP addr
#

username=$(${pkgs.coreutils}/bin/cat ${update_ddns_root}/ddns_user)
password=$(${pkgs.coreutils}/bin/cat ${update_ddns_root}/ddns_pwd)
domain="${letsEncryptHost}"
use_ipv6=1
use_https=1
force_ipversion=0
retry_count=0
USE_CURL=0

# Extract the ipv6 address
ipv6Prefix=$(${pkgs.iproute2}/bin/ip -6 addr show dev ${eth-dev} | ${pkgs.gnugrep}/bin/grep -v 'mngtmpaddr' | ${pkgs.gnugrep}/bin/grep -v 'deprecated' | ${pkgs.gnugrep}/bin/grep 'global' | ${pkgs.gnugrep}/bin/grep -oP 'inet6 \K[0-9a-fA-F:]+(?=/)' | ${pkgs.coreutils}/bin/head -n 1)
__IP=''${ipv6Prefix%/??}

VERBOSE=0		# default mode is log to console, but easily changed with parameter

DATFILE="/tmp/dat.file"		# save stdout data of WGet and other external programs called
ERRFILE="/tmp/err.file"		# save stderr output of WGet and other external programs called
${pkgs.coreutils}/bin/rm -f "$DATFILE"
${pkgs.coreutils}/bin/rm -f "$ERRFILE"

RETRY_SECONDS=0		# in configuration

URL_USER=""		# url encoded $username from config file
URL_PASS=""		# url encoded $password from config file

PID_SLEEP=0		# ProcessID of current background "sleep"

# Transfer Programs
WGET=${pkgs.wget}/bin/wget
$WGET -V 2>/dev/null | ${pkgs.gnugrep}/bin/grep -F -q +https && WGET_SSL=$WGET

CURL=${pkgs.curl}/bin/curl
# CURL_SSL not empty then SSL support available
CURL_SSL=$($CURL -V 2>/dev/null | ${pkgs.gnugrep}/bin/grep -F "https")

# replace all special chars to their %hex value
# used for USERNAME and PASSWORD in update_url
# unchanged: "-"(minus) "_"(underscore) "."(dot) "~"(tilde)
# to verify: "'"(single quote) '"'(double quote)	# because shell delimiter
#            "$"(Dollar)				# because used as variable output
# tested with the following string stored via Luci Application as password / username
# A B!"#AA$1BB%&'()*+,-./:;<=>?@[\]^_`{|}~	without problems at Dollar or quotes
urlencode() {
	# $1	Name of Variable to store encoded string to
	# $2	string to encode
	local __ENC

	[ $# -ne 2 ] && ${pkgs.coreutils}/bin/echo "Error calling 'urlencode()' - wrong number of parameters" && exit

	__ENC="$(${pkgs.gawk}/bin/awk -v str="$2" 'BEGIN{ORS="";for(i=32;i<=127;i++)lookup[sprintf("%c",i)]=i
		for(k=1;k<=length(str);++k){enc=substr(str,k,1);if(enc!~"[-_.~a-zA-Z0-9]")enc=sprintf("%%%02x", lookup[enc]);print enc}}')"

	eval "$1=\"$__ENC\""	# transfer back to variable
	return 0
}

do_transfer() {
	# $1	# URL to use
	local __URL="$1"
	local __ERR=0
	local __CNT=0	# error counter
	local __PROG  __RUNPROG

	[ $# -ne 1 ] && ${pkgs.coreutils}/bin/echo "Error in 'do_transfer()' - wrong number of parameters" && exit

	# Use ip_network as default for bind_network if not separately specified
	[ -z "$bind_network" ] && [ "$ip_source" = "network" ] && [ "$ip_network" ] && bind_network="$ip_network"

	# lets prefer GNU Wget because it does all for us - IPv4/IPv6/HTTPS/PROXY/force IP version
	if [ -n "$WGET_SSL" ] && [ $USE_CURL -eq 0 ]; then 			# except global option use_curl is set to "1"
		__PROG="$WGET --hsts-file=/tmp/.wget-hsts -nv -t 1 -O $DATFILE -o $ERRFILE"	# non_verbose no_retry outfile errfile
		# force network/ip to use for communication
		if [ -n "$bind_network" ]; then
			local __BINDIP
			# set correct program to detect IP
			[ $use_ipv6 -eq 0 ] && __RUNPROG="network_get_ipaddr" || __RUNPROG="network_get_ipaddr6"
			eval "$__RUNPROG __BINDIP $bind_network" || \
				${pkgs.coreutils}/bin/echo "Can not detect local IP using '$__RUNPROG $bind_network' - Error: '$?'" && exit
			${pkgs.coreutils}/bin/echo "Force communication via IP '$__BINDIP'"
			__PROG="$__PROG --bind-address=$__BINDIP"
		fi
		# force ip version to use
		if [ $force_ipversion -eq 1 ]; then
			[ $use_ipv6 -eq 0 ] && __PROG="$__PROG -4" || __PROG="$__PROG -6"	# force IPv4/IPv6
		fi
		# set certificate parameters
		if [ $use_https -eq 1 ]; then
			if [ "$cacert" = "IGNORE" ]; then	# idea from Ticket #15327 to ignore server cert
				__PROG="$__PROG --no-check-certificate"
			elif [ -f "$cacert" ]; then
				__PROG="$__PROG --ca-certificate=''${cacert}"
			elif [ -d "$cacert" ]; then
				__PROG="$__PROG --ca-directory=''${cacert}"
			elif [ -n "$cacert" ]; then		# it's not a file and not a directory but given
				${pkgs.coreutils}/bin/echo "No valid certificate(s) found at '$cacert' for HTTPS communication" && exit
			fi
		fi
		# disable proxy if no set (there might be .wgetrc or .curlrc or wrong environment set)
		[ -z "$proxy" ] && __PROG="$__PROG --no-proxy"

		# user agent string if provided
		if [ -n "$user_agent" ]; then
			# replace single and double quotes
			user_agent=$(${pkgs.coreutils}/bin/echo $user_agent | ${pkgs.gnused}/bin/sed "s/'/ /g" | ${pkgs.gnused}/bin/sed 's/"/ /g')
			__PROG="$__PROG --user-agent='$user_agent'"
		fi

		__RUNPROG="$__PROG '$__URL'"	# build final command
		__PROG="GNU Wget"		# reuse for error logging

	# 2nd choice is cURL IPv4/IPv6/HTTPS
	# libcurl might be compiled without Proxy or HTTPS Support
	elif [ -n "$CURL" ]; then
		__PROG="$CURL -RsS -o $DATFILE --stderr $ERRFILE"
		# check HTTPS support
		[ -z "$CURL_SSL" -a $use_https -eq 1 ] && \
			${pkgs.coreutils}/bin/echo "cURL: libcurl compiled without https support" && exit
		# force network/interface-device to use for communication
		if [ -n "$bind_network" ]; then
			local __DEVICE
			network_get_device __DEVICE $bind_network || \
				${pkgs.coreutils}/bin/echo "Can not detect local device using 'network_get_device $bind_network' - Error: '$?'" && exit
			${pkgs.coreutils}/bin/echo "Force communication via device '$__DEVICE'"
			__PROG="$__PROG --interface $__DEVICE"
		fi
		# force ip version to use
		if [ $force_ipversion -eq 1 ]; then
			[ $use_ipv6 -eq 0 ] && __PROG="$__PROG -4" || __PROG="$__PROG -6"	# force IPv4/IPv6
		fi
		# set certificate parameters
		if [ $use_https -eq 1 ]; then
			if [ "$cacert" = "IGNORE" ]; then	# idea from Ticket #15327 to ignore server cert
				__PROG="$__PROG --insecure"	# but not empty better to use "IGNORE"
			elif [ -f "$cacert" ]; then
				__PROG="$__PROG --cacert $cacert"
			elif [ -d "$cacert" ]; then
				__PROG="$__PROG --capath $cacert"
			elif [ -n "$cacert" ]; then		# it's not a file and not a directory but given
				${pkgs.coreutils}/bin/echo "No valid certificate(s) found at '$cacert' for HTTPS communication" && exit
			fi
		fi
		# disable proxy if no set (there might be .wgetrc or .curlrc or wrong environment set)
		# or check if libcurl compiled with proxy support
		if [ -z "$proxy" ]; then
			__PROG="$__PROG --noproxy '*'"
		elif [ -z "$CURL_PROXY" ]; then
			# if libcurl has no proxy support and proxy should be used then force ERROR
			${pkgs.coreutils}/bin/echo "cURL: libcurl compiled without Proxy support" && exit
		fi

		__RUNPROG="$__PROG '$__URL'"	# build final command
		__PROG="cURL"			# reuse for error logging

	# uclient-fetch possibly with ssl support if /lib/libustream-ssl.so installed
	elif [ -n "$UCLIENT_FETCH" ]; then
		# UCLIENT_FETCH_SSL not empty then SSL support available
		UCLIENT_FETCH_SSL=$(find /lib /usr/lib -name libustream-ssl.so* 2>/dev/null)
		__PROG="$UCLIENT_FETCH -q -O $DATFILE"
		# force network/ip not supported
		[ -n "$__BINDIP" ] && \
			${pkgs.coreutils}/bin/echo "uclient-fetch: FORCE binding to specific address not supported" && exit
		# force ip version to use
		if [ $force_ipversion -eq 1 ]; then
			[ $use_ipv6 -eq 0 ] && __PROG="$__PROG -4" || __PROG="$__PROG -6"       # force IPv4/IPv6
		fi
		# https possibly not supported
		[ $use_https -eq 1 -a -z "$UCLIENT_FETCH_SSL" ] && \
			${pkgs.coreutils}/bin/echo "uclient-fetch: no HTTPS support! Additional install one of ustream-ssl packages" && exit
		# proxy support
		[ -z "$proxy" ] && __PROG="$__PROG -Y off" || __PROG="$__PROG -Y on"
		# https & certificates
		if [ $use_https -eq 1 ]; then
			if [ "$cacert" = "IGNORE" ]; then
				__PROG="$__PROG --no-check-certificate"
			elif [ -f "$cacert" ]; then
				__PROG="$__PROG --ca-certificate=$cacert"
			elif [ -n "$cacert" ]; then		# it's not a file; nothing else supported
				${pkgs.coreutils}/bin/echo "No valid certificate file '$cacert' for HTTPS communication" && exit
			fi
		fi
		__RUNPROG="$__PROG '$__URL' 2>$ERRFILE"		# build final command
		__PROG="uclient-fetch"				# reuse for error logging

	# Busybox Wget or any other wget in search $PATH (did not support neither IPv6 nor HTTPS)
	elif [ -n "$WGET" ]; then
		__PROG="$WGET -q -O $DATFILE"
		# force network/ip not supported
		[ -n "$__BINDIP" ] && \
			${pkgs.coreutils}/bin/echo "BusyBox Wget: FORCE binding to specific address not supported" && exit
		# force ip version not supported
		[ $force_ipversion -eq 1 ] && \
			${pkgs.coreutils}/bin/echo "BusyBox Wget: Force connecting to IPv4 or IPv6 addresses not supported" && exit
		# https not supported
		[ $use_https -eq 1 ] && \
			${pkgs.coreutils}/bin/echo "BusyBox Wget: no HTTPS support" && exit
		# disable proxy if no set (there might be .wgetrc or .curlrc or wrong environment set)
		[ -z "$proxy" ] && __PROG="$__PROG -Y off"

		__RUNPROG="$__PROG '$__URL' 2>$ERRFILE"		# build final command
		__PROG="Busybox Wget"				# reuse for error logging

	else
		${pkgs.coreutils}/bin/echo "Neither 'Wget' nor 'cURL' nor 'uclient-fetch' installed or executable" && exit
	fi

	while : ; do
		${pkgs.coreutils}/bin/echo "#> $__RUNPROG"
		eval $__RUNPROG			# DO transfer
		__ERR=$?			# save error code
		[ $__ERR -eq 0 ] && return 0	# no error leave

		${pkgs.coreutils}/bin/echo "$__PROG Error: '$__ERR'"
		${pkgs.coreutils}/bin/echo "$(${pkgs.coreutils}/bin/cat $ERRFILE)"		# report error

		[ $VERBOSE -gt 1 ] && {
			# VERBOSE > 1 then NO retry
			${pkgs.coreutils}/bin/echo "Transfer failed - Verbose Mode: $VERBOSE - NO retry on error"
			return 1
		}

		__CNT=$(( $__CNT + 1 ))	# increment error counter
		# if error count > retry_count leave here
		[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && \
			${pkgs.coreutils}/bin/echo "Transfer failed after $retry_count retries" && return 1

		${pkgs.coreutils}/bin/echo "Transfer failed - retry $__CNT/$retry_count in $RETRY_SECONDS seconds"
		${pkgs.coreutils}/bin/sleep $RETRY_SECONDS &
		PID_SLEEP=$!
		wait $PID_SLEEP	# enable trap-handler
		PID_SLEEP=0
	done
	# we should never come here there must be a programming error
	${pkgs.coreutils}/bin/echo "Error in 'do_transfer()' - program coding error"
}

[ -n "$username" ] && urlencode URL_USER "$username"
[ -n "$password" ] && urlencode URL_PASS "$password"

#__DUMMY
__UPDURL6="http://[USERNAME]:[PASSWORD]@dynupdate6.noip.com/nic/update?hostname=[DOMAIN]&myip=[IP]"
__UPDURL="http://[USERNAME]:[PASSWORD]@dynupdate.noip.com/nic/update?hostname=[DOMAIN]&myip=[IP]"
# inside url we need username and password
[ -z "$URL_USER" ] && ${pkgs.coreutils}/bin/echo "Service section not configured correctly! Missing 'URL_USER'" && exit
[ -z "$URL_PASS" ] && ${pkgs.coreutils}/bin/echo "Service section not configured correctly! Missing 'URL_PASS'" && exit
[ -z "$__IP" ] && ${pkgs.coreutils}/bin/echo "Service section not configured correctly! Missing '__IP'" && exit
[ -z "$domain" ] && ${pkgs.coreutils}/bin/echo "Service section not configured correctly! Missing 'domain'" && exit

# set IP version dependend dummy (localhost)
[ $use_ipv6 -eq 0 ] && __DUMMY="127.0.0.1" || __DUMMY="::1"
[ $use_ipv6 -eq 0 ] && __UPDURL=$__UPDURL || __UPDURL=$__UPDURL6

# lets do DUMMY transfer
${pkgs.coreutils}/bin/echo "sending dummy IP to 'no-ip.com'"
__URL=$(${pkgs.coreutils}/bin/echo $__UPDURL | ${pkgs.gnused}/bin/sed -e "s#\[USERNAME\]#$URL_USER#g" -e "s#\[PASSWORD\]#$URL_PASS#g" \
			       -e "s#\[DOMAIN\]#$domain#g" -e "s#\[IP\]#$__DUMMY#g")
[ $use_https -ne 0 ] && __URL=$(${pkgs.coreutils}/bin/echo $__URL | ${pkgs.gnused}/bin/sed -e 's#^http:#https:#')

do_transfer "$__URL" || exit 1

${pkgs.coreutils}/bin/echo "'no-ip.com' answered:''${N}$(${pkgs.coreutils}/bin/cat $DATFILE)"
# analyse provider answers
# "good [IP_ADR]"	= successful
# "nochg [IP_ADR]"	= no change but OK
${pkgs.gnugrep}/bin/grep -E "good|nochg" $DATFILE >/dev/null 2>&1 || exit 1

# lets wait a seconds
${pkgs.coreutils}/bin/sleep 1

# now send the correct data
${pkgs.coreutils}/bin/echo "sending real IP to 'no-ip.com'"
__URL=$(${pkgs.coreutils}/bin/echo $__UPDURL | ${pkgs.gnused}/bin/sed -e "s#\[USERNAME\]#$URL_USER#g" -e "s#\[PASSWORD\]#$URL_PASS#g" \
			       -e "s#\[DOMAIN\]#$domain#g" -e "s#\[IP\]#$__IP#g")
[ $use_https -ne 0 ] && __URL=$(${pkgs.coreutils}/bin/echo $__URL | ${pkgs.gnused}/bin/sed -e 's#^http:#https:#')

do_transfer "$__URL" || exit 1

${pkgs.coreutils}/bin/echo "'no-ip.com' answered:''${N}$(${pkgs.coreutils}/bin/cat $DATFILE)"
# analyse provider answers
# "good [IP_ADR]"	= successful
# "nochg [IP_ADR]"	= no change but OK
${pkgs.gnugrep}/bin/grep -E "good|nochg" $DATFILE >/dev/null 2>&1 || exit 1

${pkgs.coreutils}/bin/rm -f "$DATFILE"
${pkgs.coreutils}/bin/rm -f "$ERRFILE"

router_pwd=$(${pkgs.coreutils}/bin/cat ${update_ddns_root}/router_pwd)
${myPythonWithPackages}/bin/python ${update_router_forwards} "$router_pwd" "$__IP"
    '';
  };
}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
