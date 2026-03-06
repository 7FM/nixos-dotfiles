{ config, pkgs, lib, ... }:

let
  myTools = pkgs.myTools { osConfig = config; };
  governor = config.custom.cpuFreqGovernor;
  enableLaptopPowerSaving = config.custom.laptopPowerSaving;
in {

  # Power management
  powerManagement = {
    enable = true;
    # power-profiles-daemon manages governors dynamically, so don't set a static one
    cpuFreqGovernor = lib.mkIf (!enableLaptopPowerSaving) governor;
  };

  # power-profiles-daemon for runtime profile switching (power-saver, balanced, performance)
  # Use `powerprofilesctl` to switch profiles
  services.power-profiles-daemon.enable = enableLaptopPowerSaving;

  # Battery charge thresholds (managed separately from power-profiles-daemon)
  services.upower = lib.mkIf enableLaptopPowerSaving {
    enable = true;
    percentageLow = 20;
    percentageCritical = 10;
  };

  # Charge thresholds via sysfs (ThinkPad-compatible)
  systemd.services.battery-charge-threshold = lib.mkIf enableLaptopPowerSaving {
    description = "Set battery charge thresholds";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ -f /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
        echo 70 > /sys/class/power_supply/BAT0/charge_control_start_threshold
        echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold
      fi
    '';
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

