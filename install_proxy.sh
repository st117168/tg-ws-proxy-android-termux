pkg install python python-cryptography
pip install certifi

cd ~
git clone --no-checkout --filter=blob:none https://github.com/Flowseal/tg-ws-proxy/
cd ~/tg-ws-proxy
git sparse-checkout init --cone
git sparse-checkout set proxy
git checkout
find . -maxdepth 1 -type f -delete
find . -maxdepth 1 -type d ! -name "proxy" ! -name ".git" -exec rm -rf {} +
