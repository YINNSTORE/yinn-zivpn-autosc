#!/bin/bash
set -euo pipefail
clear

if command -v speedtest >/dev/null 2>&1; then
  speedtest
elif command -v speedtest-cli >/dev/null 2>&1; then
  speedtest-cli
else
  echo "speedtest belum ada. Install:"
  echo "apt update && apt install -y speedtest-cli"
fi
echo ""
read -rp "Enter..." _