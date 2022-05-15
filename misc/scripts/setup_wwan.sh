#!/bin/sh
qmicli -p -d /dev/cdc-wdm0 --device-open-mbim --dms-set-fcc-authentication
#systemctl restart ModemManager.service
