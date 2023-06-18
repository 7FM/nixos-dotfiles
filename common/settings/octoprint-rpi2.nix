{ config, lib, pkgs, modulesPath, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
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
        git.enable = true;
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

  services.octoprint = {
    enable = true;
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
      heatertimeout
      gcodeeditor
      floatingnavbar
      excluderegion
      enclosure
      emergencystopsimplified
      bltouch
      autoscroll
      octolapse
      bedlevelvisualizer
      bedlevelingwizard
      arc_welder
      octoprint-dashboard
      multilineterminal
      displaylayerprogress
    ];
  };
  services.klipper = {
    enable = true;
    octoprintIntegration = true;
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
        z_offset = 2.98;
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
