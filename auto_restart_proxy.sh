#!/bin/bash

SCRIPT_NAME="auto_restart_proxy.sh"
source "$(dirname "$0")/lib_common.sh"

INTERVAL=3600

cleanup() {
    log "WARN" "received stop signal, shutting down"
    kill_proxy
    rm -f "$AUTO_PID_FILE"
    # wake-unlock здесь НЕ делаем — только через close_proxy.sh
    exit 0
}
trap cleanup SIGINT SIGTERM

# --- Защита от повторного запуска ---
if [ -f "$AUTO_PID_FILE" ]; then
    OLD_PID=$(cat "$AUTO_PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        log "WARN" "auto_restart already running (pid=$OLD_PID), exiting"
		safe_termux_open "https://t.me"
        log "OK" "telegram opened with existing link"
        exit 0
    else
        log "WARN" "stale auto_restart pid file, removing"
        rm -f "$AUTO_PID_FILE"
    fi
fi

echo $$ > "$AUTO_PID_FILE"

# --- Обёртка: операция под локом ---
with_lock() {
    exec 9>"$LOCK_FILE"
    trap 'exec 9>&-' EXIT
    if ! flock -n 9; then
        log "WARN" "lock busy, waiting up to 10s"
        flock -w 10 9 || { log "ERROR" "lock timeout"; exec 9>&-; return 1; }
    fi
    "$@"
    local rc=$?
    exec 9>&-
    return $rc
}

# --- Первичный запуск ---
do_initial_start() {
    if [ -n "$(proxy_pid)" ]; then
        log "WARN" "existing proxy detected, stopping before auto_restart"
        kill_proxy
    fi

    wake_lock
    log "INFO" "=== auto_restart started (interval=${INTERVAL}s, pid=$$) ==="

    SECRET=""
    if [ -f "$SECRET_FILE" ]; then
        SAVED=$(cat "$SECRET_FILE" 2>/dev/null)
        if validate_secret "$SAVED"; then
            SECRET="$SAVED"
            log "INFO" "using saved secret from $SECRET_FILE"
        else
            log "WARN" "saved secret invalid, will generate new"
            rm -f "$SECRET_FILE"
        fi
    fi

    if [ -z "$SECRET" ]; then
        SECRET=$(start_proxy_process new)
        if [ -z "$SECRET" ]; then
            log "ERROR" "initial start failed"
            return 1
        fi
        echo "$SECRET" > "$SECRET_FILE"
        log "OK" "new secret generated and saved"
        safe_termux_open "tg://proxy?server=$PROXY_SERVER&port=$PROXY_PORT&secret=dd$SECRET"
        log "OK" "telegram opened with proxy link"
    else
        OUT=$(start_proxy_process "fixed:$SECRET")
        if [ -z "$OUT" ]; then
            log "ERROR" "initial start with saved secret failed"
            return 1
        fi
        log "OK" "proxy started with saved secret"
		safe_termux_open "https://t.me"
        log "OK" "telegram opened with existing link"
    fi
    return 0
}

if ! with_lock do_initial_start; then
    rm -f "$AUTO_PID_FILE"
    exit 1
fi

# --- Рестарт ---
do_restart() {
    if [ -f "$SECRET_FILE" ]; then
        NEW=$(cat "$SECRET_FILE" 2>/dev/null)
        if validate_secret "$NEW"; then
            SECRET="$NEW"
        fi
    fi
    log "INFO" "hourly restart initiated"
    kill_proxy
    OUT=$(start_proxy_process "fixed:$SECRET")
    if [ -z "$OUT" ]; then
        log "ERROR" "restart failed, will retry next hour"
    else
        log "OK" "proxy restarted with saved secret"
    fi
}

# --- Цикл ---
while true; do
    sleep "$INTERVAL"
    with_lock do_restart
done