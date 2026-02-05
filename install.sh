#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="YINNSTORE"
GITHUB_REPO="yinn-zivpn-autosc"
BRANCH="main"

REPO_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${BRANCH}"
WORKDIR="/usr/local/yinn-zivpn"
SCRIPTS_DIR="${WORKDIR}/scripts"

BASE="/etc/yinn-zivpn"
CONF_DIR="${BASE}"
USERS_DIR="${BASE}/users"

BIN="/usr/local/bin/zivpn"
SVC_FILE="/etc/systemd/system/zivpn.service"

need_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Run as root"; exit 1; }
}

pause() { read -rp "Enter untuk lanjut..." _; }

install_pkgs() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y \
    bash curl wget jq openssl ca-certificates \
    iproute2 net-tools vnstat \
    iptables cron tzdata \
    unzip git \
    python3 python3-pip \
    speedtest-cli \
    lolcat || true

  timedatectl set-timezone Asia/Jakarta >/dev/null 2>&1 || true
  systemctl enable vnstat >/dev/null 2>&1 || true
  systemctl restart vnstat >/dev/null 2>&1 || true
}

fetch_file() {
  local rel="$1"
  local out="$2"
  curl -fsSL "${REPO_RAW_BASE}/${rel}" -o "${out}"
}

setup_scripts() {
  mkdir -p "${SCRIPTS_DIR}"

  fetch_file "scripts/menu.sh"         "${SCRIPTS_DIR}/menu.sh"
  fetch_file "scripts/user_manager.sh" "${SCRIPTS_DIR}/user_manager.sh"
  fetch_file "scripts/settings.sh"     "${SCRIPTS_DIR}/settings.sh"
  fetch_file "scripts/backup.sh"       "${SCRIPTS_DIR}/backup.sh"
  fetch_file "scripts/bandwidth.sh"    "${SCRIPTS_DIR}/bandwidth.sh"
  fetch_file "scripts/speedtest.sh"    "${SCRIPTS_DIR}/speedtest.sh"

  chmod +x "${SCRIPTS_DIR}/"*.sh
}

setup_command_menu() {
  ln -sf "${SCRIPTS_DIR}/menu.sh" /usr/local/sbin/menu
  ln -sf "${SCRIPTS_DIR}/menu.sh" /usr/local/bin/menu

  if [[ -f /root/.bashrc ]] && ! grep -q "/usr/local/sbin" /root/.bashrc; then
    echo 'export PATH="/usr/local/sbin:/usr/local/bin:$PATH"' >> /root/.bashrc
  fi
  if [[ -f /root/.profile ]] && ! grep -q "/usr/local/sbin" /root/.profile; then
    echo 'export PATH="/usr/local/sbin:/usr/local/bin:$PATH"' >> /root/.profile
  fi
}

input_domain() {
  mkdir -p "${CONF_DIR}" "${USERS_DIR}" >/dev/null 2>&1

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " AUTOSCRIPT ZIVPN - YINN STORE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local d
  read -rp "Input Domain (wajib): " d
  if [[ -z "${d:-}" ]]; then
    echo "Domain kosong. ulangin."
    exit 1
  fi
  echo -n "$d" > "${CONF_DIR}/domain"
}

install_core() {
  local d url def
  d="$(cat "${CONF_DIR}/domain" 2>/dev/null || true)"

  def="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
  echo ""
  read -rp "Core URL (Enter=default): " url
  [[ -z "${url:-}" ]] && url="$def"

  echo "Download core..."
  curl -fsSL "$url" -o "$BIN"
  chmod +x "$BIN"

  echo "Write config..."
  cat > "${CONF_DIR}/config.json" <<'EOF'
{
  "listen": ":5667",
  "server_name": "ZiVPN",
  "log_level": "info"
}
EOF

  echo "Generate SSL self-signed..."
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=JawaBarat/L=Jampang/O=YinnStore/OU=ZiVPN/CN=${d}" \
    -keyout "${CONF_DIR}/zivpn.key" -out "${CONF_DIR}/zivpn.crt" >/dev/null 2>&1

  echo "Write systemd..."
  cat > "$SVC_FILE" <<EOF
[Unit]
Description=ZiVPN UDP Core (YinnStore)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${CONF_DIR}
ExecStart=${BIN} server -c ${CONF_DIR}/config.json
Restart=always
RestartSec=2
LimitNOFILE=65535
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable zivpn.service >/dev/null 2>&1
  systemctl restart zivpn.service >/dev/null 2>&1
}

final_info() {
  echo ""
  echo "✅ INSTALL SELESAI"
  echo "Command: menu"
  echo "Service: systemctl status zivpn.service"
  echo "Domain : $(cat "${CONF_DIR}/domain" 2>/dev/null || echo '-')"
  echo "Path   : ${WORKDIR}"
  echo ""
}

main() {
  need_root
  install_pkgs
  setup_scripts
  setup_command_menu
  input_domain
  install_core
  hash -r || true
  final_info

  exec menu
}

main "$@"