#!/bin/bash

SCRIPT_NAME="close_proxy.sh"
source "$(dirname "$0")/lib_common.sh"
trap 'if [ "$TERMUX_OPENED" -eq 0 ]; then minimize_termux; fi' EXIT

# --- Остановить auto_restart ---
if [ -f "$AUTO_PID_FILE" ]; then
    AUTO_PID=$(cat "$AUTO_PID_FILE" 2>/dev/null)
    if [ -n "$AUTO_PID" ] && kill -0 "$AUTO_PID" 2>/dev/null; then
        kill "$AUTO_PID" 2>/dev/null
        for _ in $(seq 1 10); do
            kill -0 "$AUTO_PID" 2>/dev/null || break
            sleep 0.3
        done
        kill -0 "$AUTO_PID" 2>/dev/null && kill -9 "$AUTO_PID" 2>/dev/null
        log "INFO" "auto_restart stopped (pid=$AUTO_PID)"
    else
        log "WARN" "auto_restart pid file stale, removing"
    fi
    rm -f "$AUTO_PID_FILE"
else
    log "WARN" "auto_restart not running"
fi

# --- Остановить прокси ---
kill_proxy

# --- Снять wake-lock полностью ---
wake_release_all

# --- На всякий случай освободить fd 9, если остался ---
exec 9>&- 2>/dev/null || true