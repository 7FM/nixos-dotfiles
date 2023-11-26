{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  myPorts = (myTools.getSecret ../../nixos "usedPorts.nix") myTools;

  mySeafileSecrets = (myTools.getSecret ../../nixos "seafile.nix");
  myLetsEncryptSecrets = (myTools.getSecret ../../nixos "letsencrypt.nix");
  myRadicaleSecrets = (myTools.getSecret ../../nixos "radicale.nix");
  myNFSSecrets = (myTools.getSecret ../../nixos "nfs.nix");
  myMiscSecrets = (myTools.getSecret ../../nixos "misc.nix");

  letsEncryptHost = myLetsEncryptSecrets.letsEncryptHost;
  letsEncryptEmail = myLetsEncryptSecrets.letsEncryptEmail;
  seafileAdminEmail = mySeafileSecrets.seafileAdminEmail;
  seafileInitialAdminPwd = mySeafileSecrets.seafileInitialAdminPwd;
  seafileTmpPath = mySeafileSecrets.seafileTmpPath;

  radicaleMntPoint = myMiscSecrets.radicaleMntPoint;
  downloadRoot = myMiscSecrets.downloadRoot;
  giteaAppName = myMiscSecrets.giteaAppName;
  nfsExports = myNFSSecrets.nfsExports;

  # Exposed ports
  radicalePort = myTools.extractPort myPorts.radicale "";
  downloadPort = myTools.extractPort myPorts.downloadPage "";
  jenkinsPort =  myTools.extractPort myPorts.jenkins "proxy";
  giteaPort = myTools.extractPort myPorts.gitea "proxy";
  seafilePort = myTools.extractPort myPorts.seafile "proxy";
  nfsMountdPort = myTools.extractPort myPorts.nfs "mountd";
  nfsPortmapperPort = myTools.extractPort myPorts.nfs "portmapper";
  nfsNfsdPort = myTools.extractPort myPorts.nfs "nfsd";
  openvpnServerPort = myTools.extractPort myPorts.openvpn_server "";
  # Hidden internal ports
  giteaInternalPort = myTools.extractPort myPorts.gitea "internal";
  seafileInternalPort = myTools.extractPort myPorts.seafile "seafileInternal";
  jenkinsInternalPort = myTools.extractPort myPorts.jenkins "internal";
  syncthingHttpPort = myTools.extractPort myPorts.syncthing "";
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
  custom.enableVirtualisation = false;
  custom.adb = "disabled";
  custom.smartcards = false;
  custom.nano_conf.enable = true;
  custom.networking = {
    nfsSupport = false;
    wifiSupport = false;
    withNetworkManager = false;
    openvpn.client = {
      enable = false;
      autoConnect = false;
    };
  };
  custom.security = {
    gnupg.enable = false;
    usbguard = {
      enforceRules = true;
      fixedRules = myTools.getSecret ../../nixos "usbguard-rules.nix";
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


  # Server configuration

  #TODO hard drive & mount configuration!

  # Backups
  services.btrbk = {
    #TODO
  };

  # Server certificate: Let's Encrypt!
  security.acme = {
    acceptTerms = true;
    defaults.email = letsEncryptEmail;
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
        listen = createListenEntries radicalePort;
        locations = defaultLocations // {
          "/" = {
            proxyPass = "http://localhost:5232/";
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

      jenkins = (defaultConf ''
        #pass through headers from Jenkins which are considered invalid by Nginx server.
        ignore_invalid_headers off;
        ## Only allow these request methods ##
        if ($request_method !~ ^(GET|HEAD|POST)$ ) {
            return 403;
        }
        ## Do not accept DELETE, SEARCH and other methods ##
      '') // {
        listen = createListenEntries jenkinsPort;
        locations = defaultLocations // {
          "/" = {
            proxyPass = "http://localhost:${toString config.services.jenkins.port}/";
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

      seafile = (defaultConf ''
      '') // {
        extraConfig = ''
          proxy_set_header   X-Forwarded-For $remote_addr;
        '';
        listen = createListenEntries seafilePort;
        locations = defaultLocations // {
          "/" = {
            recommendedProxySettings = false;
            proxyPass = "http://unix:/run/seahub/gunicorn.sock";
            extraConfig = ''
              proxy_set_header   X-Forwarded-Host $server_name;
              proxy_set_header   Host $host:$server_port;
              proxy_set_header   X-Real-IP $remote_addr;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header   X-Forwarded-Proto $scheme;
              proxy_connect_timeout  3600s;
              proxy_read_timeout  3600s;
              proxy_send_timeout  3600s;
              send_timeout  3600s;

              client_max_body_size 0;
              client_body_temp_path ${seafileTmpPath};
              # access_log      /var/log/nginx/seahub.access.log;
              # error_log       /var/log/nginx/seahub.error.log;
            '';
          };
          "/seafhttp" = {
            recommendedProxySettings = false;
            proxyPass = "http://localhost:${toString config.services.seafile.seafileSettings.fileserver.port}";
            extraConfig = ''
              rewrite ^/seafhttp(.*)$ $1 break;

              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_connect_timeout  3600s;
              proxy_read_timeout  3600s;
              proxy_send_timeout  3600s;
              proxy_request_buffering off;
              send_timeout  3600s;
              client_max_body_size 0;
              client_body_temp_path ${seafileTmpPath};
              # access_log      /var/log/nginx/seafhttp.access.log;
              # error_log       /var/log/nginx/seafhttp.error.log;
            '';
          };
        };
      };



    };
  };

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

  # File server: Seafile
  services.seafile = rec {
    enable = true;
    adminEmail = seafileAdminEmail;
    initialAdminPassword = seafileInitialAdminPwd;
    # workers = 2;
    ccnetSettings = {
      General.SERVICE_URL = "https://${letsEncryptHost}:${toString seafilePort}";
    };

    seafileSettings = {
      fileserver.port = seafileInternalPort;
      general.enable_syslog = true;
    };
    # TODO there is currently no seafdav support in nixos :'(
    # [WEBDAV]
    # enabled = true
    # port = 4242
    # share_name = /

    # seahubExtraConf = ''
    #   DEBUG = True
    # '';
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

  # Jenkins server:
  services.jenkins = {
    enable = true;
    port = jenkinsInternalPort;
    listenAddress = "localhost";
    extraJavaOptions = [
      "-Djava.awt.headless=true"
      "-Xmx128m"
      "-Djava.net.preferIPv4Stack=true"
    ];
    withCLI = true;
    # packages = [] add extra packages into the service path
    # plugins = TODO use jenkinsPlugins2nix
  };

  # NFS server
  services.nfs.server = {
    enable = true;
    nproc = 4;
    mountdPort = nfsMountdPort;
    exports = nfsExports;
  };

  #TODO pihole?
  
  # Syncthing
  services.syncthing = {
    enable = true;
    systemService = true;
    openDefaultPorts = true;
    guiAddress = "127.0.0.1:${toString syncthingHttpPort}";
    #TODO we could hardcode which devices & folders are allowed
  };

  # VPN server
  services.openvpn.servers.server = {
    #TODO change path
    # config = ''config /home/${userName}/vpns/server.ovpn'';
    config = ''config /home/tm/vpns/server.ovpn'';
    autoStart = true;
  };

  # TODO DryNoMore
  #TODO Compal shitty router scripting
}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
