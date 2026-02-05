#!/bin/bash
set -euo pipefail
clear

get_default_iface(){ ip -4 route ls 2>/dev/null | awk '/default/ {print $5; exit}'; }
IFACE="$(get_default_iface)"; [[ -z "$IFACE" ]] && IFACE="eth0"

DATE="$(date -d "0 days" +"%Y-%m-%d")"
ttoday="$(vnstat -i "$IFACE" 2>/dev/null | grep "today" | awk '{print $8" "substr ($9, 1, 1)}')"
tmon="$(vnstat -i "$IFACE" -m 2>/dev/null | grep "$(date +"%b '%y")" | awk '{print $9" "substr ($10, 1, 1)}')"

echo "━━━━━ [ BANDWIDTH MONITORING ] ━━━━━"
echo ""
echo "Interface: [$IFACE]"
echo "Hari Ini [$DATE]         Bulan Ini [$(date +%B-%Y)]"
echo "↓↓ Total: ${ttoday:-0}           ↓↓ Total: ${tmon:-0}"
echo ""
vnstat -i "$IFACE" 2>/dev/null || echo "vnstat belum ada / belum aktif."
echo ""
read -rp "Enter..." _