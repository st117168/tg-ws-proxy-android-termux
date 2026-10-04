#!/bin/bash

SCRIPT_NAME="install_proxy.sh"

echo "=== tg-ws-proxy installer ==="
echo

# --- 1. Пакеты ---
echo "[*] checking required packages..."
MISSING=""
for pkg in git python python-cryptography; do
    if ! pkg list-installed 2>/dev/null | grep -q "^$pkg/"; then
        MISSING="$MISSING $pkg"
    fi
done

if [ -n "$MISSING" ]; then
    echo "[*] installing missing packages:$MISSING"
    pkg install -y $MISSING
    if [ $? -ne 0 ]; then
        echo "[!] ERROR: failed to install packages:$MISSING"
        exit 1
    fi
    echo "[+] packages installed:$MISSING"
else
    echo "[+] all packages already installed"
fi

# --- 2. certifi ---
echo "[*] installing certifi via pip..."
pip install --quiet certifi
if [ $? -ne 0 ]; then
    echo "[!] WARN: pip install certifi failed (maybe not critical)"
else
    echo "[+] certifi installed"
fi

# --- 3. Клонирование tg-ws-proxy ---
cd ~ || { echo "[!] ERROR: cannot cd to home"; exit 1; }

if [ -d "$HOME/tg-ws-proxy/.git" ]; then
    echo "[*] tg-ws-proxy already cloned, updating..."
    cd ~/tg-ws-proxy || { echo "[!] ERROR: cannot cd to ~/tg-ws-proxy"; exit 1; }
    git pull
else
    echo "[*] cloning tg-ws-proxy..."
    git clone --no-checkout --filter=blob:none https://github.com/Flowseal/tg-ws-proxy/
    if [ $? -ne 0 ]; then
        echo "[!] ERROR: git clone failed"
        exit 1
    fi
    cd ~/tg-ws-proxy || { echo "[!] ERROR: cannot cd to ~/tg-ws-proxy"; exit 1; }
fi

# --- 4. sparse-checkout ---
echo "[*] configuring sparse-checkout..."
git sparse-checkout init --cone
git sparse-checkout set proxy
git checkout

find . -maxdepth 1 -type f -delete
find . -maxdepth 1 -type d ! -name "proxy" ! -name ".git" -exec rm -rf {} +

if [ ! -f "$HOME/tg-ws-proxy/proxy/tg_ws_proxy.py" ]; then
    echo "[!] ERROR: tg_ws_proxy.py not found after checkout"
    exit 1
fi
echo "[+] tg-ws-proxy ready"

# --- 5. Проверка --secret ---
cd "$HOME/tg-ws-proxy/proxy" || exit 1
if python tg_ws_proxy.py --help 2>&1 | grep -q -- "--secret"; then
    echo "[+] --secret supported"
else
    echo "[!] WARN: --secret NOT supported"
fi

# --- 6. flock ---
if ! command -v flock > /dev/null 2>&1; then
    echo "[*] flock not found, installing util-linux..."
    pkg install -y util-linux
fi

# --- 7. Права на скрипты ---
echo "[*] fixing permissions on scripts..."
sed -i 's/\r$//' ~/.shortcuts/tg-ws-proxy-android-termux/*.sh 2>/dev/null
chmod +x ~/.shortcuts/tg-ws-proxy-android-termux/*.sh 2>/dev/null

# --- 8. Готово ---
echo
echo "=== Installation complete ==="
echo "Add a Termux:Widget on your home screen and select the folder:"
echo "  ~/.shortcuts/tg-ws-proxy-android-termux"
echo
echo "Shortcuts: start_proxy.sh, auto_restart_proxy.sh, close_proxy.sh, etc."