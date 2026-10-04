# Installation
1. Install termux and termux:widget from F-droid
2. In the termux console execute:

2.1. Install packages
```bash
pkg install git python python-cryptography
```
2.2. Install program
```bash
mkdir -p ~/.shortcuts
cd ~/.shortcuts
git clone https://github.com/st117168/tg-ws-proxy-android-termux
sed -i 's/\r$//' ~/.shortcuts/tg-ws-proxy-android-termux/*.sh
chmod +x ~/.shortcuts/tg-ws-proxy-android-termux/*.sh
~/.shortcuts/tg-ws-proxy-android-termux/install_proxy.sh
cd ~
```

3. Allow termux to run in background in android app settings

# Usage

Add a Termux:Widget on your home screen and select the folder:
`~/.shortcuts/tg-ws-proxy-android-termux`

Then just tap a shortcut. Available shortcuts:

- `install_proxy.sh` — installs packages, dependencies and tg-ws-proxy. Run once.
- `start_proxy.sh` — starts the proxy with a new secret, saves it and opens Telegram with the proxy link.
- `restart_proxy.sh` — stops the running proxy and starts a new one with a new secret.
- `auto_restart_proxy.sh` — starts the proxy and restarts it every hour using the same saved secret, so Telegram does not need to be updated.
- `close_proxy.sh` — stops the proxy and auto-restart, releases the wake-lock.
- `update_proxy.sh` — updates tg-ws-proxy from GitHub.
- `delete_proxy.sh` — removes shortcuts, logs and the proxy directory.

# Notes

- The current secret is stored in `~/tg-ws-proxy/.secret`. It is reused by `auto_restart_proxy.sh` so the proxy link in Telegram stays valid.
- To force a new secret, run `start_proxy.sh` or `restart_proxy.sh`, or delete `~/tg-ws-proxy/.secret`.
- Logs are written to `~/tg-ws-proxy/proxy_log.txt` in the format:
  `[YYYY-MM-DD HH:MM:SS] [script.sh] [LEVEL] message`
  Levels: `INFO`, `OK`, `WARN`, `ERROR`.
- Only `close_proxy.sh` releases the wake-lock. All other scripts only acquire it.
- To view logs:

```bash
tail -50 ~/tg-ws-proxy/proxy_log.txt
```
```bash
grep ERROR ~/tg-ws-proxy/proxy_log.txt
```

To verify the current state (no duplicate processes, valid secret, wake-lock counter):

```bash
~/.shortcuts/tg-ws-proxy-android-termux/check.sh
```

- Normal output of `check.sh`:
  - `proxy:` is `0` (proxy stopped) or `1` (proxy running).
  - `auto_restart:` is `0` (auto-restart stopped) or `1` (auto-restart running).
  - `start:`, `restart:`, `close:` are always `0` — these scripts are one-shot and must exit immediately.
  - `wake_count:` is `0` when everything is stopped. It is `1` after starting the proxy once, `2` after starting it again without closing, and so on. This is normal — each start acquires one wake-lock. Run `close_proxy.sh` to reset it to `0`.
  - `secret valid:` is `1` if the proxy has ever been started, otherwise `0`.
- If `check.sh` shows `2` or more for any process, or `start` / `restart` / `close` is not `0`, or `wake_count` is negative — something is stuck or duplicated. Run `close_proxy.sh`, then check again.
- Typical states:
  - Everything off: all fields `0`, `wake_count: 0`, `secret valid` may be `0` or `1`.
  - Proxy started manually: `proxy: 1`, `auto_restart: 0`, `wake_count: 1`.
  - Proxy with auto-restart: `proxy: 1`, `auto_restart: 1`, `wake_count: 1`.
  - Proxy with auto-restart + manual restart: `proxy: 1`, `auto_restart: 1`, `wake_count: 2`.