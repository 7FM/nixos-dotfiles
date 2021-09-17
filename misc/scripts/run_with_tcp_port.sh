#!/usr/bin/env bash
# Source: https://discourse.nixos.org/t/how-to-temporarily-open-a-tcp-port-in-nixos/12306/2
# Usage: sudo run-with-port <port> <cmd> <args...>

set -ueo pipefail

open-port() {
  local port=$1
  iptables -I INPUT -p tcp --dport $port -j ACCEPT
}

close-port() {
  local port=${1:-0}
  iptables -D INPUT -p tcp --dport $port -j ACCEPT
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

open-port $PORT

# Ensure port closes if error occurs.
trap "close-port $PORT" EXIT

# Run the command as user, not root.
runuser -u $SUDO_USER -- "$@"

# Trap will close port.
