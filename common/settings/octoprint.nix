{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  myPorts = (myTools.getSecret ../../nixos "usedPorts.nix") myTools;

  myMiscSecrets = (myTools.getSecret ../../nixos "misc.nix");

  zigbee2mqttFrontendPort = myTools.extractPort myPorts.zigbee2mqtt "frontend";
  mqttPort = myTools.extractPort myPorts.mosquitto "mqtt";
  octoprintInternal = myTools.extractPort myPorts.octoprint "internal";
  octoprintProxy = myTools.extractPort myPorts.octoprint "proxy";
  hassInternalPort = myTools.extractPort myPorts.homeassistant "internal";
  hassProxyPort = myTools.extractPort myPorts.homeassistant "proxy";
  mjpegStreamerPort = myTools.extractPort myPorts.mjpegStreamer "";
  mqttUser = myMiscSecrets.mqtt.user;
  mqttPwd = myMiscSecrets.mqtt.pwd;

  localStaticIP = myMiscSecrets.localStaticIP;
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

    "/var/lib/octoprint/storage" = {
      device = "/dev/disk/by-uuid/392a260b-9f69-4fa2-9d81-1ba569937188";
      fsType = "ext4";
    };
  };

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 4*1024;
  }];

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

    # https://github.com/Electrostasy/dots/blob/3b81723feece67610a252ce754912f6769f0cd34/hosts/phobos/klipper.nix#L11
    apply-overlays-dtmerge.enable = true;
  };

  boot = {
    # Give the GPU some memory # TODO we can probably reduce the amount!
    kernelParams = [ "cma=512M" ];
  };
  hardware.deviceTree = {
    enable = true;

    # https://github.com/Electrostasy/dots/blob/3b81723feece67610a252ce754912f6769f0cd34/hosts/phobos/klipper.nix#L17-L42
    filter = "bcm2711-rpi-4-b.dtb";
    overlays =
      let
        mkCompatibleDtsFile = dtbo:
          let
            drv = pkgs.runCommand "fix-dts" { nativeBuildInputs = with pkgs; [ dtc gnused ]; } ''
              mkdir "$out"
              dtc -I dtb -O dts ${dtbo} | sed -e 's/bcm2835/bcm2711/' > $out/overlay.dts
            '';
          in
            "${drv}/overlay.dts";

        inherit (config.boot.kernelPackages) kernel;
      in
        [
          # https://www.raspberrypi.com/documentation/accessories/camera.html#hardware-specification
          # {
          #   # HQ Camera
          #   name = "imx477.dtbo";
          #   dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/imx477.dtbo";
          # }
          # {
          #   # GS Camera
          #   name = "imx296.dtbo";
          #   dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/imx296.dtbo";
          # }
          # {
          #   # AI Camera
          #   name = "imx500.dtbo";
          #   dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/imx500.dtbo";
          # }
          # {
          #   # Camera Module v3
          #   name = "imx708.dtbo";
          #   dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/imx708.dtbo";
          # }
          {
            # Camera Module v2
            name = "imx219.dtbo";
            dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/imx219.dtbo";
          }
          # {
          #   # Camera Module v1
          #   name = "ov5647.dtbo";
          #   dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/ov5647.dtbo";
          # }
          # GPU support
          {
            name = "vc4-kms-v3d-pi4.dtbo";
            dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/vc4-kms-v3d-pi4.dtbo";
          }
        ];
  };

  # Make gpio accessible to everyone in the gpio group
  users.groups.gpio = {};

  # Change permissions gpio devices
  services.udev.extraRules = ''
    # Non-root GPIO access
    SUBSYSTEM=="*gpiomem*", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", GROUP="gpio", MODE="0660", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
    SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"

    # Camera via DMA access
    # https://raspberrypi.stackexchange.com/a/141107
    SUBSYSTEM=="dma_heap", GROUP="video", MODE="0660"
  '';

  users = {
    # Add octoprint user to gpio group
    users."${config.services.octoprint.user}".extraGroups = [ "gpio" ];
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
    withNetworkManager = false;
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

    in {
      acme = (defaultConf "") // {
        enableACME = true;
        useACMEHost = null;
      };

      octoprint = (defaultConf "") // {
        http2 = false;
        listen = createListenEntries octoprintProxy;
        locations = defaultLocations // {
          "/" = {
            recommendedProxySettings = false;
            proxyWebsockets = true;
            proxyPass = "http://localhost:${toString octoprintInternal}/";
            extraConfig = ''
              proxy_set_header Host $host:$server_port;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Scheme $scheme;
              proxy_connect_timeout   60s;
              proxy_send_timeout      60s;
              proxy_read_timeout      60s;

              client_max_body_size 0; 
            '';
          };

          # TODO do we need this?
          # # redirect server error pages to the static page /50x.html
          # error_page   500 502 503 504  /50x.html;
          # location = /50x.html {
          #     root   html;
          # }
        };
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
        trusted_proxies = ["127.0.0.1" "::1"];
      };
      homeassistant.unit_system = "metric";
      frontend.themes = "!include_dir_merge_named themes";
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
    };
  };

  services.mjpg-streamer = {
    enable = true;
    outputPlugin = "output_http.so -w @www@ -n -p ${toString mjpegStreamerPort}";
    inputPlugin = "input_uvc.so -r 1280x720 -f 10 -vf true -hf true -d /dev/video0";
  };

  services.octoprint = {
    enable = true;
    port = octoprintInternal;
    plugins = plugins: with plugins; [
      uploadanything
      themeify
      webcamtab
      taborder
      simpleemergencystop
      psucontrol
      printtimegenius
      navbartemp
      multipleupload
      heatertimeout # TODO check functionality
      gcodeeditor
      floatingnavbar
      excluderegion # TODO check functionality
      enclosure
      emergencystopsimplified # TODO check functionality
      bltouch # TODO check functionality
      autoscroll
      # octolapse # TODO marked as broken
      bedlevelvisualizer
      bedlevelingwizard # TODO check functionality
      arc_welder
      # TODO report / fix broken alias: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/oc/octoprint/plugins.nix#L669 remove super.
      dashboard
      multilineterminal
      displaylayerprogress
    ];
    extraConfig = myMiscSecrets.octoprint.extraConfig mjpegStreamerPort;
  };
  services.klipper = {
    enable = true;
    octoprintIntegration = config.services.octoprint.enable;

    firmwares = {
      mcu = {
        enable = true;
        configFile = ../../home-manager/configs/klipper/skr_e3_dip.cfg;
        enableKlipperFlash = true; # NOTE: this is not supported, but we at least want to keep the firmware to allow manual flashing
      };
    };

    settings = let 
      stepperSettings = { step_pin, dir_pin, enable_pin, rotation_distance ? 40}: {
        inherit step_pin dir_pin enable_pin rotation_distance;
        microsteps = 16;
      };

      tmc2208Conf = uart_pin: {
        inherit uart_pin;
        run_current = 0.580;
        stealthchop_threshold = 999999;
      };
    in rec {
      # This file contains common pin mappings for the BIGTREETECH SKR E3
      # DIP. To use this config, the firmware should be compiled for the
      # STM32F103 with a "28KiB bootloader" and USB communication. Also,
      # select "Enable extra low-level configuration options" and configure
      # "GPIO pins to set at micro-controller startup" to "!PC13".

      # The "make flash" command does not work on the SKR E3 DIP. Instead,
      # after running "make", copy the generated "out/klipper.bin" file to a
      # file named "firmware.bin" on an SD card and then restart the SKR E3
      # DIP with that SD card.

      # See docs/Config_Reference.md for a description of parameters.

      # Note: This board has a design flaw in its thermistor circuits that
      # cause inaccurate temperatures (most noticeable at low temperatures).

      stepper_x = (stepperSettings {
        step_pin = "PC6";
        dir_pin = "!PB15";
        enable_pin = "!PC7";
      }) // {
        endstop_pin = "^PC1";
        position_endstop = 0;
        position_max = 235;
        homing_speed = 50;
      };

      stepper_y = (stepperSettings {
        step_pin = "PB13";
        dir_pin = "PB12";
        enable_pin = "!PB14";
      }) // {
        endstop_pin = "^PC0";
        position_endstop = 0;
        position_max = 235;
        homing_speed = 50;
      };

      stepper_z = (stepperSettings {
        step_pin = "PB10";
        dir_pin = "!PB2";
        enable_pin = "!PB11";
        rotation_distance = 8;
      }) // {
        endstop_pin = "probe:z_virtual_endstop";
        position_max = 250;
      };

      extruder = (stepperSettings {
        step_pin = "PB0";
        dir_pin = "PC5";
        enable_pin = "!PB1";
        rotation_distance = 33.5;
      }) // {
        nozzle_diameter = 0.4;
        filament_diameter = 1.75;
        heater_pin = "PC8";
        sensor_type = "EPCOS 100K B57560G104F";
        sensor_pin = "PA0";
        control = "pid";
        pid_Kp = 22.74;
        pid_Ki = 2.03;
        pid_Kd = 63.81;
        min_temp = 0;
        max_temp = 250;
      };

      heater_bed = {
        heater_pin = "PC9";
        sensor_type = "ATC Semitec 104GT-2";
        sensor_pin = "PC3";
        control = "pid";
        pid_Kp = 54.027;
        pid_Ki = 0.770;
        pid_Kd = 948.182;
        min_temp = 0;
        max_temp = 130;
      };

      fan = {
        pin = "PA8";
      };

      bltouch = {
        sensor_pin = "^PC15";
        control_pin = "PA1";
        # TODO first ensure that horizontal_move_z is large enough!
        # stow_on_each_sample = false;
        # probe_with_touch_mode = true;
        x_offset = 48;
        y_offset = -2;
        # z_offset = 2.98;
        z_offset = 4.3;
      };

      safe_z_home = {
        home_xy_position = "${builtins.toString (stepper_x.position_max / 2 - bltouch.x_offset)}, ${builtins.toString (stepper_y.position_max / 2 - bltouch.y_offset)}";
        speed = 50;
        z_hop = 10;
        z_hop_speed = 5;
      };

      # https://www.klipper3d.org/Bed_Mesh.html
      bed_mesh = {
        horizontal_move_z = 8;
        mesh_min = "${builtins.toString (bltouch.x_offset)}, 10";
        mesh_max = "${builtins.toString (stepper_x.position_max - 10)}, ${builtins.toString (stepper_y.position_max - 10)}";
        probe_count = 5;
      };

      "gcode_macro G29" = {
        gcode = [
          ''{% if printer.toolhead.homed_axes != "xyz" %}''
          "  G28"
          "{% endif %}"
          "BED_MESH_CALIBRATE"
        ];
      };

      # filament runout sensor
      "filament_switch_sensor my_sensor" = {
        pause_on_runout = true;
        runout_gcode = [
          "PAUSE"
        ];
        insert_gcode = [
          "RESUME"
        ];
        event_delay = 3.0;
        pause_delay = 0.5;
        switch_pin = "^PC2";
      };

      gcode_arcs = {};

      # resonance compensation
      # use the rpi as secondary MCU
      # "mcu rpi".serial = "/tmp/klipper_host_mcu";
      # acceleration sensor at the bed is connected to the RPi
      # "adxl345 bed" = {
      #   cs_pin = "rpi:None";
      # };
      # acceleration sensor at the hotend is connected to the MCU
      # "adxl345 hotend" = {
      #   cs_pin = "PB6";
      # };
      # resonance_tester = {
      #   accel_chip_x = "adxl345 hotend";
      #   accel_chip_y = "adxl345 bed";
      #   probe_points = "${builtins.toString (stepper_x.position_max / 2)}, ${builtins.toString (stepper_y.position_max / 2)}, 20";
      # };

      mcu.serial = "/dev/serial/by-id/usb-Klipper_stm32f103xe_33FFDC054E43383414842043-if00";

      printer = {
        kinematics = "cartesian";
        max_velocity = 300;
        max_accel = 3000;
        max_z_velocity = 5;
        max_z_accel = 100;
      };

      "static_digital_output usb_pullup_enable" = {
        pins = "!PC13";
      };

      ########################################
      # TMC2208 configuration
      ########################################

      "tmc2208 stepper_x" = tmc2208Conf "PC10";
      "tmc2208 stepper_y" = tmc2208Conf "PC11";
      "tmc2208 stepper_z" = tmc2208Conf "PC12";

      "tmc2208 extruder" = (tmc2208Conf "PD2") // { run_current = 0.650; };

      ########################################
      # EXP1 (display) pins
      ########################################

      board_pins = {
        # EXP1 header
        aliases = "EXP1_1=PA15, EXP1_3=PA9, EXP1_5=PA10, EXP1_7=PB8, EXP1_9=<GND>, EXP1_2=PB6, EXP1_4=<RST>, EXP1_6=PB9, EXP1_8=PB7, EXP1_10=<5V>";
      };

      # See the sample-lcd.cfg file for definitions of common LCD displays.
    };
  };

}
(import (modulesPath + "/installer/scan/not-detected.nix") { inherit lib; })
]
