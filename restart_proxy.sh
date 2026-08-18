#!/bin/bash

PROXY_DIR="$HOME/tg-ws-proxy/proxy"
PROXY_SERVER="127.0.0.1"
PROXY_PORT="1443"

PID=$(pgrep -f "tg_ws_proxy.py")

if [ -n "$PID" ]; then
    kill "$PID"
    termux-wake-unlock
    echo "$(date +"%Y-%m-%d %H:%M:%S") - proxy stopped." >> ~/tg-ws-proxy/proxy_log.txt
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - proxy already stopped." >> ~/tg-ws-proxy/proxy_log.txt
fi

extract_secret() {
    echo "$1" | grep -oP "Secret:\s+\K[a-f0-9]+" | head -1
}

cd "$PROXY_DIR" || { echo "$(date +"%Y-%m-%d %H:%M:%S") - error PROXY_DIR" >> ~/tg-ws-proxy/proxy_log.txt; exit 1; }

TEMP_LOG=$(mktemp)
nohup python tg_ws_proxy.py > "$TEMP_LOG" 2>&1 &
echo "$(date +"%Y-%m-%d %H:%M:%S") - proxy started." >> ~/tg-ws-proxy/proxy_log.txt

SECRET=$(extract_secret "$(cat $TEMP_LOG)")
rm -f "$TEMP_LOG"

if [ -n "$SECRET" ]; then
    termux-open "tg://proxy?server=$PROXY_SERVER&port=$PROXY_PORT&secret=dd$SECRET"
        echo "$(date +"%Y-%m-%d %H:%M:%S") - telegram opened." >> ~/tg-ws-proxy/proxy_log.txt
    termux-wake-lock
fi