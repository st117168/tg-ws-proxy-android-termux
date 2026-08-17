# Installation
1. Install termux and termux:widget from F-droid
2. In the termux console execute:
```bash
pkg install git
cd ~/.shortcuts
git clone https://github.com/st117168/tg-ws-proxy-android-termux
sed -i 's/\r$//' ~/.shortcuts/tg-ws-proxy-android-termux/*.sh
chmod +x ~/.shortcuts/tg-ws-proxy-android-termux/*.sh
./install_proxy.sh
rm -rf ~/.shortcuts/tg-ws-proxy-android-termux/{.git,README.md,LICENSE,install_proxy.sh}