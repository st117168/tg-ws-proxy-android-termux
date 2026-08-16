#!/bin/bash

PID=$(pgrep -f "tg_ws_proxy.py")

if [ -n "$PID" ]; then
    kill "$PID"
    termux-wake-unlock
    echo "$(date +"%Y-%m-%d %H:%M:%S") - proxy stopped." >> ~/proxy_log.txt
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - proxy wasn't stopped." >> ~/proxy_log.txt
fi