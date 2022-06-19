#!/bin/sh
set -ueo pipefail

failed() {
  echo "Failed to open the KeepassXC database!"
}

trap 'failed' ERR

KEEPASSDB_PATH="/home/tm/KeyManager/keepass.kdbx"
KEEPASSDB_SEARCHTERM="hrz"
UNI_VPN_URL="vpn.hrz.tu-darmstadt.de"
UNI_VPN_GROUP="campus" # All traffic will be routed through the VPN
#UNI_VPN_GROUP="extern" # Only uni targets will be routed through the VPN -> most traffic is unsecured!

stty -echo
printf "Please enter the Keepass Password: "
read KP_PASSWORD
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
