#!/bin/bash
set -euo pipefail
clear

BASE="/etc/yinn-zivpn"
USERS="$BASE/users"
mkdir -p "$USERS" >/dev/null 2>&1

safe_int(){ echo "${1:-0}" | tr -cd '0-9'; }
pause(){ read -rp "Enter..." _; }

while true; do
  clear
  echo "=== MENU USER ZIVPN (YINN) ==="
  echo "1) Create User (json)"
  echo "2) Renew User (days)"
  echo "3) Delete User"
  echo "4) List Users"
  echo "0) Back"
  echo
  read -rp "Selected ⟩ " c
  case "$c" in
    1)
      read -rp "Username: " u
      read -rp "Days: " d
      d="$(safe_int "$d")"; [[ -z "$d" ]] && d=1
      [[ -z "$u" ]] && echo "Kosong." && pause && continue
      expd="$(date -d "+$d days" +"%Y-%m-%d" 2>/dev/null)"
      cat > "$USERS/$u.json" <<EOF
{"username":"$u","days":$d,"created":"$(date +%F\ %T)","expired":"$expd"}
EOF
      echo "✅ Created: $u (exp: $expd)"
      pause
      ;;
    2)
      read -rp "Username: " u
      read -rp "Tambah Days: " d
      d="$(safe_int "$d")"; [[ -z "$d" ]] && d=1
      f="$USERS/$u.json"
      [[ ! -f "$f" ]] && echo "User tidak ada." && pause && continue
      oldexp="$(jq -r '.expired // empty' "$f" 2>/dev/null)"
      [[ -z "$oldexp" ]] && oldexp="$(date +%F)"
      newexp="$(date -d "$oldexp +$d days" +"%Y-%m-%d" 2>/dev/null)"
      tmp="$(mktemp)"
      jq --arg e "$newexp" '.expired=$e' "$f" > "$tmp" 2>/dev/null && mv "$tmp" "$f"
      echo "✅ Renew: $u (exp: $newexp)"
      pause
      ;;
    3)
      read -rp "Username: " u
      rm -f "$USERS/$u.json"
      echo "✅ Deleted: $u"
      pause
      ;;
    4)
      echo ""
      echo "=== USERS ==="
      ls -1 "$USERS"/*.json 2>/dev/null | sed 's#.*/##;s#.json##' || echo "Kosong."
      echo ""
      pause
      ;;
    0) exit 0 ;;
    *) ;;
  esac
done