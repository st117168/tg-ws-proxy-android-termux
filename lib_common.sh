#!/bin/bash
# Общие функции для всех скриптов tg-ws-proxy
# Подключать: source "$(dirname "$0")/lib_common.sh"

# Глобальный флаг: открывали ли Telegram
TERMUX_OPENED=0

PROXY_DIR="$HOME/tg-ws-proxy/proxy"
PROXY_SERVER="127.0.0.1"
PROXY_PORT="1443"
SECRET_FILE="$HOME/tg-ws-proxy/.secret"
LOG_FILE="$HOME/tg-ws-proxy/proxy_log.txt"
LOCK_FILE="$HOME/tg-ws-proxy/.lock"
AUTO_PID_FILE="$HOME/tg-ws-proxy/.auto_restart.pid"
WAKE_COUNT_FILE="$HOME/tg-ws-proxy/.wake_count"

mkdir -p "$HOME/tg-ws-proxy"

# ---- Свернуть Termux (вернуться на домашний экран) ----
minimize_termux() {
    am start -a android.intent.action.MAIN -c android.intent.category.HOME > /dev/null 2>&1
    log "INFO" "termux minimized"
}

# ---- Логирование ----
log() {
    local level="$1"; shift
    local name="${SCRIPT_NAME:-unknown.sh}"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$name] [$level] $*" >> "$LOG_FILE"
}

# ---- Валидация secret ----
validate_secret() {
    local s="$1"
    [[ "$s" =~ ^[a-f0-9]{32}$ ]]
}

# ---- Точный поиск PID прокси ----
proxy_pid() {
    pgrep -f "python.*tg_ws_proxy\.py" | head -1
}

# ---- Проверка поддержки --secret ----
supports_secret_arg() {
    cd "$PROXY_DIR" 2>/dev/null || return 1
    python tg_ws_proxy.py --help 2>&1 | grep -q -- "--secret"
}

# ---- Извлечение secret из вывода ----
extract_secret() {
    echo "$1" | grep -oP "Secret:\s+\K[a-f0-9]{32}" | head -1
}

# ---- Убийство прокси с ожиданием ----
kill_proxy() {
    local PID
    PID=$(proxy_pid)
    if [ -z "$PID" ]; then
        log "WARN" "proxy already stopped"
        return 0
    fi
    log "INFO" "stopping proxy pid=$PID"
    kill "$PID" 2>/dev/null
    for _ in $(seq 1 10); do
        kill -0 "$PID" 2>/dev/null || break
        sleep 0.3
    done
    if kill -0 "$PID" 2>/dev/null; then
        log "WARN" "proxy didn't die, sending SIGKILL"
        kill -9 "$PID" 2>/dev/null
        sleep 0.3
    fi
    if kill -0 "$PID" 2>/dev/null; then
        log "ERROR" "failed to kill proxy pid=$PID"
        return 1
    fi
    log "INFO" "proxy stopped (pid=$PID)"
    return 0
}

# ---- Wake-lock со счётчиком ----
wake_lock() {
    local count=0
    [ -f "$WAKE_COUNT_FILE" ] && count=$(cat "$WAKE_COUNT_FILE" 2>/dev/null || echo 0)
    count=$((count + 1))
    echo "$count" > "$WAKE_COUNT_FILE"
    termux-wake-lock 2>/dev/null
    log "INFO" "wake-lock acquired (count=$count)"
}

# Полный сброс wake-lock (для close_proxy.sh)
wake_release_all() {
    echo "0" > "$WAKE_COUNT_FILE"
    termux-wake-unlock 2>/dev/null
    log "OK" "wake-lock fully released"
}

# Уменьшение счётчика
wake_unlock() {
    local count=0
    [ -f "$WAKE_COUNT_FILE" ] && count=$(cat "$WAKE_COUNT_FILE" 2>/dev/null || echo 0)
    if [ "$count" -le 1 ]; then
        wake_release_all
    else
        count=$((count - 1))
        echo "$count" > "$WAKE_COUNT_FILE"
        log "INFO" "wake-lock decremented (count=$count)"
    fi
}

# ---- termux-open: проверка + не наследовать fd 9 ----
safe_termux_open() {
    local url="$1"
    if command -v termux-open > /dev/null 2>&1; then
        termux-open "$url" 9>&- 2>/dev/null
        TERMUX_OPENED=1
        return 0
    fi
    log "WARN" "termux-open not available, cannot open: $url"
    return 1
}

# ---- Запуск прокси ----
# $1 = "fixed:<secret>" | "new"
# stdout = secret при успехе
start_proxy_process() {
    local mode="$1"
    cd "$PROXY_DIR" || { log "ERROR" "cannot cd to $PROXY_DIR"; return 1; }

    if [ "$mode" = "new" ]; then
        local TEMP_LOG
        TEMP_LOG=$(mktemp)
        nohup python tg_ws_proxy.py 9>&- > "$TEMP_LOG" 2>&1 &
        sleep 1.5
        if [ -z "$(proxy_pid)" ]; then
            log "ERROR" "proxy failed to start"
            cat "$TEMP_LOG" >> "$LOG_FILE" 2>/dev/null
            rm -f "$TEMP_LOG"
            return 1
        fi
        local SECRET
        SECRET=$(extract_secret "$(cat "$TEMP_LOG")")
        rm -f "$TEMP_LOG"
        if [ -z "$SECRET" ]; then
            log "ERROR" "secret not found in proxy output"
            return 1
        fi
        echo "$SECRET"
        return 0
    fi

    local SECRET="${mode#fixed:}"
    if ! validate_secret "$SECRET"; then
        log "ERROR" "invalid secret format: $SECRET"
        return 1
    fi

    if supports_secret_arg; then
        nohup python tg_ws_proxy.py --secret "$SECRET" 9>&- > /dev/null 2>&1 &
    else
        log "WARN" "--secret not supported, starting without it"
        nohup python tg_ws_proxy.py 9>&- > /dev/null 2>&1 &
    fi
    sleep 1.5

    if [ -z "$(proxy_pid)" ]; then
        log "ERROR" "proxy failed to start with fixed secret"
        return 1
    fi
    echo "$SECRET"
    return 0
}