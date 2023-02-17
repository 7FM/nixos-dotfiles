{ config, pkgs, lib, osConfig, ... }:

let
  enable = true; #TODO create option?

  sway-screenshare = pkgs.writeShellApplication {
    name = "sway-screenshare";
    runtimeInputs = with pkgs; [
      sway
      jq
      slurp
      wf-recorder
    ];
    text = ''
      # Source: https://github.com/luispabon/sway-dotfiles/blob/master/scripts/sway-screenshare.sh

      set -x

      geometry(){
        windowGeometries=$(
          # `height - 1` is there because of: https://github.com/ammen99/wf-recorder/pull/56 (I could remove it if it's merged, maybe)
          swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .rect | "\(.x),\(.y) \(.width)x\(.height - 1)"'; \
          swaymsg -t get_outputs -r | jq -r '.[] | select(.active) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
        )
        geometry=$(slurp -b "#45858820" -c "#45858880" -w 3 -d <<< "$windowGeometries") || exit $?
        echo "$geometry"
      }

      # Ensure we're not using the wayland backend on SDL
      unset SDL_VIDEODRIVER

      geometry=$(geometry) || exit $?
      wf-recorder -c rawvideo --geometry="$geometry" -m sdl -f pipe:wayland-mirror

      # Alternative method via ffplay
      # wf-recorder -c rawvideo --geometry="$geometry" -x yuv420p -m avi -f pipe:99 99>&1 >&2 | ffplay -f avi - &
    '';
  };

  esa_gitlab_shuttle = pkgs.writeShellApplication {
    name = "esa_gitlab_shuttle";
    runtimeInputs = with pkgs; [
      sshuttle
    ];
    text = ''
      sshuttle --dns -r esa_erebor 130.83.161.128/26 10.0.0.0/8 -x 130.83.161.131/32
    '';
  };

  uni_vpn = pkgs.writeShellApplication {
    name = "uni_vpn";
    runtimeInputs = with pkgs; [
      openconnect
      keepassxc
      gawk
      gnugrep
    ];
    text = ''
      set -ueo pipefail

      failed() {
        echo "Failed to open the KeepassXC database!"
      }

      trap 'failed' ERR

      KEEPASSDB_PATH="/home/tm/KeyManager/keepass.kdbx"
      KEEPASSDB_SEARCHTERM="hrz-"
      UNI_VPN_URL="vpn.hrz.tu-darmstadt.de"
      UNI_VPN_GROUP="campus" # All traffic will be routed through the VPN
      #UNI_VPN_GROUP="extern" # Only uni targets will be routed through the VPN -> most traffic is unsecured!

      stty -echo
      printf "Please enter the KeepassXC Password: "
      read -r KP_PASSWORD
      stty echo
      printf "\n"

      echo "Trying to extract the VPN credentials from the KeepassXC DB"
      VPN_ENTRY=$(echo "$KP_PASSWORD" | keepassxc-cli search "$KEEPASSDB_PATH" "$KEEPASSDB_SEARCHTERM" 2> /dev/null)
      VPN_DATA=$(echo "$KP_PASSWORD" | keepassxc-cli show "$KEEPASSDB_PATH" "$VPN_ENTRY" 2> /dev/null)
      VPN_PASSWORD=$(echo "$VPN_DATA" | grep Password | awk '{print $2}')
      VPN_USER=$(echo "$VPN_DATA" | grep UserName | awk '{print $2}')

      echo "USER: $VPN_USER"
      echo "Connecting to the VPN"
      echo "$VPN_PASSWORD" | sudo openconnect -u "$VPN_USER" --authgroup="$UNI_VPN_GROUP" --passwd-on-stdin --non-inter "$UNI_VPN_URL"
    '';
  };

  run_with_creater = prot: pkgs.writeShellApplication {
    name = "run_with_${prot}_port";
    runtimeInputs = with pkgs; [
      iptables
      util-linux
    ];
    text = ''
      # Source: https://discourse.nixos.org/t/how-to-temporarily-open-a-tcp-port-in-nixos/12306/2
      # Usage: sudo run-with-port <port> <cmd> <args...>

      set -ueo pipefail

      open-port() {
        local port=$1
        iptables -I INPUT -p ${prot} --dport "$port" -j ACCEPT
      }

      close-port() {
        local port=''\${1:-0}
        iptables -D INPUT -p ${prot} --dport "$port" -j ACCEPT
      }


      if [[ -z "$1" ]]; then
        echo "Port not given" >&2
        exit 1
      fi

      PORT=$1
      shift;  # Drop port argument

      if [[ 0 -eq $# ]]; then
        echo "No command given" >&2
        exit 1
      fi

      open-port "$PORT"

      # Ensure port closes if error occurs.
      trap 'close-port $PORT' EXIT

      # Run the command as user, not root.
      runuser -u "$SUDO_USER" -- "$@"

      # Trap will close port.
    '';
  };

  run_with_tcp_port = run_with_creater "tcp";
  run_with_udp_port = run_with_creater "udp";

  wait_for_process = pkgs.writeShellApplication {
    name = "wait_for_process";
    runtimeInputs = with pkgs; [
      coreutils
    ];
    text = ''
      PID=$1
      tail --pid="$PID" -f /dev/null
    '';
   };

  scripts = [
    run_with_tcp_port
    run_with_udp_port
    wait_for_process
  ] ++ lib.optionals ((osConfig.custom.gui == "hm-wayland") || (osConfig.custom.gui == "wayland")) [
    sway-screenshare
  ] ++ lib.optionals osConfig.custom.hm.modules.ssh.enable [
    esa_gitlab_shuttle
  ] ++ lib.optionals osConfig.custom.hm.collections.office.enable [
    uni_vpn
  ];
in {
  config = lib.mkIf enable {
    home.packages = scripts;
  };
}