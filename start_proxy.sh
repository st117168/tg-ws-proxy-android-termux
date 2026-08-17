#!/bin/bash

PROXY_DIR="$HOME/tg-ws-proxy/proxy"
PROXY_SERVER="127.0.0.1"
PROXY_PORT="1443"

extract_secret() {
    echo "$1" | grep -oP "Secret:\s+\K[a-f0-9]+" | head -1
}

if pgrep -f "tg_ws_proxy.py" > /dev/null; then
    termux-open "https://t.me"
	echo "$(date +"%Y-%m-%d %H:%M:%S") - opened without proxy." >> ~/tg-ws-proxy/proxy_log.txt
    exit 0
fi

cd "$PROXY_DIR" || { echo "$(date +"%Y-%m-%d %H:%M:%S") - error PROXY_DIR" >> ~/tg-ws-proxy/proxy_log.txt; exit 1; }

TEMP_LOG=$(mktemp)
nohup python tg_ws_proxy.py > "$TEMP_LOG" 2>&1 &
echo "$(date +"%Y-%m-%d %H:%M:%S") - proxy started." >> ~/tg-ws-proxy/proxy_log.txt
sleep 1

SECRET=$(extract_secret "$(cat $TEMP_LOG)")
rm -f "$TEMP_LOG"

if [ -n "$SECRET" ]; then
    termux-open "tg://proxy?server=$PROXY_SERVER&port=$PROXY_PORT&secret=dd$SECRET"
	echo "$(date +"%Y-%m-%d %H:%M:%S") - telegram opened." >> ~/tg-ws-proxy/proxy_log.txt
    termux-wake-lock
fi
