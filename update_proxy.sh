#!/bin/bash

cd ~/tg-ws-proxy
echo "$(date +"%Y-%m-%d %H:%M:%S") - current version: $(git describe --tags --abbrev=0 | sed 's/^v//')" >> ~/proxy_log.txt
git pull >> ~/proxy_log.txt 2>&1

if [ $? -eq 0 ]; then
	echo "$(date +"%Y-%m-%d %H:%M:%S") - new version: $(git describe --tags --abbrev=0 | sed 's/^v//')" >> ~/proxy_log.txt
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Update failed" >> ~/proxy_log.txt
fi