#!/bin/bash
set -euo pipefail
clear

pause(){ read -rp "Enter..." _; }
get_default_iface(){ ip -4 route ls 2>/dev/null | awk '/default/ {print $5; exit}'; }

while true; do
  clear
  echo "=== MENU PENGATURAN ==="
  echo "1) Service Status"
  echo "2) Restart ZiVPN"
  echo "3) Iptables Fix UDP (6000-19999 -> 5667)"
  echo "0) Back"
  echo
  read -rp "Selected ⟩ " c
  case "$c" in
    1) systemctl --no-pager status zivpn.service 2>/dev/null || true; pause ;;
    2) systemctl restart zivpn.service 2>/dev/null || true; echo "✅ Restarted."; pause ;;
    3)
      iface="$(get_default_iface)"; [[ -z "$iface" ]] && iface="eth0"
      iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null \
        || iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
      echo "✅ Iptables Fix OK on iface: $iface"
      pause
      ;;
    0) exit 0 ;;
    *) ;;
  esac
done