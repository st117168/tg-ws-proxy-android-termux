#!/bin/bash

SCRIPT_NAME="restart_proxy.sh"
source "$(dirname "$0")/lib_common.sh"

exec 9>"$LOCK_FILE"
trap 'exec 9>&-; if [ "$TERMUX_OPENED" -eq 0 ]; then minimize_termux; fi' EXIT

if ! flock -n 9; then
    log "WARN" "another proxy operation is running, exiting"
    exit 1
fi

log "INFO" "restarting proxy with new secret"
kill_proxy

SECRET=$(start_proxy_process new)
if [ -z "$SECRET" ]; then
    log "ERROR" "failed to restart proxy"
    exit 1
fi

if validate_secret "$SECRET"; then
    echo "$SECRET" > "$SECRET_FILE"
    log "OK" "secret saved to $SECRET_FILE"
    safe_termux_open "tg://proxy?server=$PROXY_SERVER&port=$PROXY_PORT&secret=dd$SECRET"
    log "OK" "telegram opened with proxy link"
    wake_lock
else
    log "ERROR" "invalid secret received: $SECRET"
    kill_proxy
    exit 1
fi