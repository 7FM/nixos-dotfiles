{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  governor = config.custom.cpuFreqGovernor;
  enableTlp = config.custom.laptopPowerSaving;
in {

  # Power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = governor;
  };

  services.tlp = {
    enable = enableTlp;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # Disable boosting on battery
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;

      #Optional helps save long term battery health
      START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
      STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging
    };
  };

  hardware.bluetooth.powerOnBoot = false;
  networking.networkmanager.wifi.powersave = true;

  services.logind = {
    settings = {
      Login = {
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "lock";
        HandleLidSwitch = "lock";
      };
    };
  };

}

