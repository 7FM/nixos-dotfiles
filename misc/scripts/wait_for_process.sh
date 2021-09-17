#!/bin/sh
PID=$1
tail --pid=$PID -f /dev/null
