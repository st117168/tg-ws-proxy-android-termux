#!/bin/bash

SCRIPT_NAME="update_proxy.sh"
source "$(dirname "$0")/lib_common.sh"

cd ~/tg-ws-proxy || { log "ERROR" "cannot cd to ~/tg-ws-proxy"; exit 1; }

OLD_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
log "INFO" "current version: ${OLD_VERSION:-unknown}"

if ! git pull >> "$LOG_FILE" 2>&1; then
    log "ERROR" "git pull failed"
    exit 1
fi

NEW_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
log "OK" "updated to version: ${NEW_VERSION:-unknown}"

# Проверка, что файл на месте
if [ ! -f "$PROXY_DIR/tg_ws_proxy.py" ]; then
    log "ERROR" "tg_ws_proxy.py not found after update!"
    exit 1
fi

# Подсказка про перезапуск
if [ -n "$(proxy_pid)" ]; then
    if [ -f "$AUTO_PID_FILE" ] && kill -0 "$(cat "$AUTO_PID_FILE")" 2>/dev/null; then
        log "INFO" "auto_restart is running, new version will apply on next hourly restart"
    else
        log "INFO" "proxy is running without auto_restart, restart required to apply update"
    fi
else
    log "INFO" "proxy not running, new version will be used on next start"
fi