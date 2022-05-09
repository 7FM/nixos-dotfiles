#!/bin/sh
sudo qmicli -p -d /dev/cdc-wdm0 --device-open-mbim --dms-set-fcc-authentication
sudo systemctl restart ModemManager.service
