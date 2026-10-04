#!/bin/bash

count_script() {
    local name="$1"
    ps -eo pid,cmd 2>/dev/null \
        | grep -E "/$name\$" \
        | grep -v grep \
        | grep -v check.sh \
        | wc -l
}

echo "proxy:        $(ps -eo pid,cmd 2>/dev/null | grep -E 'python .*tg_ws_proxy\.py' | grep -v grep | wc -l)"
echo "auto_restart: $(count_script auto_restart_proxy.sh)"
echo "start:        $(count_script start_proxy.sh)"
echo "restart:      $(count_script restart_proxy.sh)"
echo "close:        $(count_script close_proxy.sh)"
echo "wake_count:   $(cat ~/tg-ws-proxy/.wake_count 2>/dev/null || echo 0)"
echo "secret valid: $(grep -cE '^[a-f0-9]{32}$' ~/tg-ws-proxy/.secret 2>/dev/null || echo 0)"