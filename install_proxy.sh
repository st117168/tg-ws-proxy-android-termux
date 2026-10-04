#!/bin/bash

SCRIPT_NAME="install_proxy.sh"

LOG_FILE="$HOME/tg-ws-proxy/proxy_log.txt"
mkdir -p "$HOME/tg-ws-proxy"

log() {
    local level="$1"; shift
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$SCRIPT_NAME] [$level] $*" >> "$LOG_FILE"
}

echo "=== tg-ws-proxy installer ==="
echo "Лог: $LOG_FILE"
echo

# --- 1. Пакеты ---
log "INFO" "checking required packages"
MISSING=""
for pkg in git python python-cryptography; do
    if ! pkg list-installed 2>/dev/null | grep -q "^$pkg/"; then
        MISSING="$MISSING $pkg"
    fi
done

if [ -n "$MISSING" ]; then
    log "INFO" "installing missing packages:$MISSING"
    echo "Устанавливаю пакеты:$MISSING"
    pkg install -y $MISSING >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR" "failed to install packages:$MISSING"
        echo "ОШИБКА: не удалось установить пакеты. Смотри лог."
        exit 1
    fi
    log "OK" "packages installed:$MISSING"
else
    log "INFO" "all packages already installed"
fi

# --- 2. certifi ---
log "INFO" "installing certifi via pip"
pip install --quiet certifi >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "WARN" "pip install certifi failed (может быть не критично)"
else
    log "OK" "certifi installed"
fi

# --- 3. Клонирование tg-ws-proxy ---
cd ~ || { log "ERROR" "cannot cd to home"; exit 1; }

if [ -d "$HOME/tg-ws-proxy/.git" ]; then
    log "INFO" "tg-ws-proxy already cloned, updating"
    cd ~/tg-ws-proxy || { log "ERROR" "cannot cd to ~/tg-ws-proxy"; exit 1; }
    git pull >> "$LOG_FILE" 2>&1
else
    log "INFO" "cloning tg-ws-proxy"
    git clone --no-checkout --filter=blob:none https://github.com/Flowseal/tg-ws-proxy/ >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR" "git clone failed"
        echo "ОШИБКА: не удалось склонировать tg-ws-proxy. Смотри лог."
        exit 1
    fi
    cd ~/tg-ws-proxy || { log "ERROR" "cannot cd to ~/tg-ws-proxy"; exit 1; }
fi

# --- 4. sparse-checkout ---
log "INFO" "configuring sparse-checkout"
git sparse-checkout init --cone >> "$LOG_FILE" 2>&1
git sparse-checkout set proxy >> "$LOG_FILE" 2>&1
git checkout >> "$LOG_FILE" 2>&1

find . -maxdepth 1 -type f -delete
find . -maxdepth 1 -type d ! -name "proxy" ! -name ".git" -exec rm -rf {} +

if [ ! -f "$HOME/tg-ws-proxy/proxy/tg_ws_proxy.py" ]; then
    log "ERROR" "tg_ws_proxy.py not found after checkout"
    echo "ОШИБКА: tg_ws_proxy.py не найден. Смотри лог."
    exit 1
fi
log "OK" "tg-ws-proxy ready"

# --- 5. Проверка --secret ---
cd "$HOME/tg-ws-proxy/proxy" || exit 1
if python tg_ws_proxy.py --help 2>&1 | grep -q -- "--secret"; then
    log "OK" "--secret supported"
else
    log "WARN" "--secret NOT supported, auto_restart will regenerate secret each time"
fi

# --- 6. flock ---
if ! command -v flock > /dev/null 2>&1; then
    log "WARN" "flock not found, installing util-linux"
    pkg install -y util-linux >> "$LOG_FILE" 2>&1
fi

# --- 7. Права на скрипты ---
log "INFO" "fixing permissions on scripts"
sed -i 's/\r$//' ~/.shortcuts/tg-ws-proxy-android-termux/*.sh 2>/dev/null
chmod +x ~/.shortcuts/tg-ws-proxy-android-termux/*.sh 2>/dev/null

# --- 8. Готово ---
log "OK" "installation completed"
echo
echo "=== Установка завершена ==="
echo "Теперь добавь виджет Termux:Widget на главный экран и выбери папку:"
echo "  ~/.shortcuts/tg-ws-proxy-android-termux"
echo
echo "Кнопки: start_proxy.sh, auto_restart_proxy.sh, close_proxy.sh и т.д."
echo "Лог: $LOG_FILE"