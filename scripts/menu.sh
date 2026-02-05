#!/bin/bash
set -euo pipefail
clear

# THEME ENGINE
DO_LOLCAT=0
if [[ -f /usr/local/sbin/theme_engine ]]; then
  # shellcheck disable=SC1091
  source /usr/local/sbin/theme_engine
else
  DO_LOLCAT=0
fi

# COLORS (VVIP feel)
t="\033[1;32m"; WB='\033[1;36m'; yy="\033[1;93m"; CYAN="\033[96m"
w="\033[1;92m"; RED='\033[0;31m'; NC='\033[0m'
gray="\e[1;30m"; grenbo="\e[92;1m"; purple="\033[1;95m"; YELL='\033[0;33m'
yellow="${YELL}"

: "${y:=${YELL}}"
: "${z:=${gray}}"
: "${gg:=${grenbo}}"
: "${Blue:=${WB}}"
: "${green:=${t}}"
: "${p:=${purple}}"
: "${g:=${t}}"

out() {
  if [[ "${DO_LOLCAT:-0}" == "1" ]] && command -v lolcat >/dev/null 2>&1; then
    echo -e "$*" | lolcat
  else
    echo -e "$*"
  fi
}

safe_int(){ echo "${1:-0}" | tr -cd '0-9'; }
need_root(){ [[ "${EUID:-$(id -u)}" -eq 0 ]] || { out "${RED}Run as root!${NC}"; exit 1; }; }
pause(){ read -rp "Enter untuk lanjut..." _; }

BASE="/etc/yinn-zivpn"
CONF="$BASE"
USERS="$BASE/users"
BIN="/usr/local/bin/zivpn"
mkdir -p "$BASE" "$USERS" >/dev/null 2>&1

readf(){ [[ -f "$1" ]] && cat "$1" || true; }

get_default_iface(){ ip -4 route ls 2>/dev/null | awk '/default/ {print $5; exit}'; }
get_my_ip(){ curl -sS ipv4.icanhazip.com 2>/dev/null || echo "-"; }

svc_label(){ systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${green}ON${NC}" || echo -e "${z}OFF${NC}"; }
count_users(){
  local n
  n="$(ls -1 "$USERS"/*.json 2>/dev/null | wc -l)"
  n="$(safe_int "$n")"; [[ -z "$n" ]] && n=0
  echo "$n"
}

SCRIPT_DIR="/usr/local/yinn-zivpn/scripts"

menu(){
  need_root

  local IFACE IPVPS domain total_users
  IFACE="$(get_default_iface)"; [[ -z "$IFACE" ]] && IFACE="eth0"
  IPVPS="$(get_my_ip)"
  domain="$(readf "$CONF/domain")"
  total_users="$(count_users)"

  local MODEL CORE RAM USAGERAM SERONLINE
  MODEL="$(grep -w PRETTY_NAME /etc/os-release | head -n1 | sed 's/PRETTY_NAME=//;s/"//g')"
  CORE="$(grep -c cpu[0-9] /proc/stat 2>/dev/null)"
  RAM="$(free -m | awk 'NR==2 {print $2}')"
  USAGERAM="$(free -m | awk 'NR==2 {print $3}')"
  SERONLINE="$(uptime -p | cut -d " " -f 2-10000)"
  local DATE TIME_NOW
  DATE="$(date -d "0 days" +"%Y-%m-%d")"
  TIME_NOW="$(date +"%Y-%m-%d %H:%M:%S")"

  clear
  out ""
  out " ${y}╭────────────────────────────────────────────────────╮${NC}"
  out " ${y}│$NC \e[44m            AUTOSCRIPT ZIVPN - YINN STORE          ${NC}${y} │$NC"
  out " ${y}╰────────────────────────────────────────────────────╯${NC}"
  out " ${y}╭────────────────────────────────────────────────────╮${NC}"
  out " ${y}│$NC$z • $NC${RED}OS     ${yy}=$NC $MODEL${NC}"
  out " ${y}│$NC$z • $NC${RED}CORE   ${yy}=$NC $CORE${NC}"
  out " ${y}│$NC$z • $NC${RED}RAM    ${yy}=$NC $USAGERAM MB / $RAM MB $NC"
  out " ${y}│$NC$z • $NC${RED}UPTIME ${yy}=$NC $SERONLINE${NC}"
  out " ${y}│$NC$z • $NC${RED}DOMAIN ${yy}=$z ${domain:-"-"}${NC}"
  out " ${y}│$NC$z • $NC${RED}IP     ${yy}=$z $IPVPS${NC}"
  out " ${y}│$NC$z • $NC${RED}TIME   ${yy}=$z $TIME_NOW${NC}"
  out " ${y}╰─────────────────────────────────────────────────────╯${NC}"

  out " ${y}╭────────────────────────────────────────────────────╮${NC}"
  out " ${y}│ ${NC}${Blue} ZiVPN$NC : $(svc_label zivpn.service) ${y}│$NC Users: ${green}${total_users}${NC} ${y}│$NC"
  out " ${y}╰────────────────────────────────────────────────────╯${NC}"

  out " ${y}╭────────────────────────────────────────────────────╮${NC}"
  out " ${y}│$NC   ${Blue}[${p}01${NC}${Blue}]$NC ${gg}MENU USER ZIVPN       $NC   ${Blue}[${p}06${NC}${Blue}]$NC ${gg}MENU PENGATURAN $y │$NC"
  out " ${y}│$NC   ${Blue}[${p}02${NC}${Blue}]$NC ${gg}INSTALL CORE ZIVPN    $NC   ${Blue}[${p}07${NC}${Blue}]$NC ${gg}INFO BHADWITH  $y │$NC"
  out " ${y}│$NC   ${Blue}[${p}03${NC}${Blue}]$NC ${gg}CHECK SPEEDTEST       $NC   ${Blue}[${p}08${NC}${Blue}]$NC ${gg}BACKUP/RESTORE $y │$NC"
  out " ${y}│$NC   ${Blue}[${p}04${NC}${Blue}]$NC ${gg}SERVICE STATUS        $NC   ${Blue}[${p}09${NC}${Blue}]$NC ${gg}RELOAD MENU     $y │$NC"
  out " ${y}│$NC   ${Blue}[${p}05${NC}${Blue}]$NC ${gg}SHOW PATH/INFO        $NC   ${Blue}[${p}10${NC}${Blue}]$NC ${gg}EXIT           $y │$NC"
  out " ${y}╰────────────────────────────────────────────────────╯${NC}"
  echo

  read -p "  Selected Menu ⟩ " opt
  echo -e ""
  case "$opt" in
    1) bash "$SCRIPT_DIR/user_manager.sh" ;;
    2) bash "$SCRIPT_DIR/core_install.sh" ;;
    3) bash "$SCRIPT_DIR/speedtest.sh" ;;
    4) systemctl --no-pager status zivpn.service 2>/dev/null || true; pause ;;
    5) out "BASE: $BASE"; out "USERS: $USERS"; out "CONFIG: $CONF/config.json"; out "BIN: $BIN"; pause ;;
    6) bash "$SCRIPT_DIR/settings.sh" ;;
    7) bash "$SCRIPT_DIR/bandwidth.sh" ;;
    8) bash "$SCRIPT_DIR/backup.sh" ;;
    9) ;;
   10) exit 0 ;;
    *) ;;
  esac
}

while true; do menu; done