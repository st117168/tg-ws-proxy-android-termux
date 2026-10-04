#!/bin/bash

SCRIPT_NAME="delete_proxy.sh"
source "$(dirname "$0")/lib_common.sh"

log "INFO" "deleting shortcuts, logs and proxy directory"

if [ -f "$WAKE_COUNT_FILE" ]; then
    termux-wake-unlock 2>/dev/null
fi

rm -rf ~/.shortcuts/tg-ws-proxy-android-termux \
       ~/tg-ws-proxy/proxy_log.txt \
       ~/tg-ws-proxy