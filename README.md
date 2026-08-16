# installing
pkg install git python python-cryptography
pip install certifi

git clone --no-checkout --filter=blob:none https://github.com/Flowseal/tg-ws-proxy/
cd tg-ws-proxy
git sparse-checkout init --cone
git sparse-checkout set proxy
git checkout
find . -maxdepth 1 -type f -delete
find . -maxdepth 1 -type d ! -name "proxy" ! -name ".git" -exec rm -rf {} +

cd ~/.shortcuts
git clone https://github.com/st117168/tg-ws-proxy-android-termux
rm -f README.md .git LICENSE

chmod +x ~/.shortcuts/start_proxy.sh ~/.shortcuts/close_proxy.sh ~/.shortcuts/update_proxy.sh ~/.shortcuts/delete_proxy
