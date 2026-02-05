#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="YINNSTORE"
GITHUB_REPO="yinn-zivpn-autosc"
BRANCH="main"

REPO_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${BRANCH}"
WORKDIR="/usr/local/yinn-zivpn"
SCRIPTS_DIR="${WORKDIR}/scripts"

need_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Run as root"; exit 1; }
}

install_pkgs() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y \
    bash curl wget jq openssl ca-certificates \
    iproute2 net-tools vnstat \
    iptables cron tzdata \
    python3 python3-pip \
    unzip git \
    speedtest-cli \
    lolcat || true

  timedatectl set-timezone Asia/Jakarta >/dev/null 2>&1 || true

  # enable vnstat if exists
  systemctl enable vnstat >/dev/null 2>&1 || true
  systemctl restart vnstat >/dev/null 2>&1 || true
}

fetch_file() {
  local rel="$1"
  local out="$2"
  curl -fsSL "${REPO_RAW_BASE}/${rel}" -o "${out}"
}

setup_files() {
  mkdir -p "${SCRIPTS_DIR}"

  fetch_file "scripts/menu.sh"        "${SCRIPTS_DIR}/menu.sh"
  fetch_file "scripts/user_manager.sh" "${SCRIPTS_DIR}/user_manager.sh"
  fetch_file "scripts/settings.sh"    "${SCRIPTS_DIR}/settings.sh"
  fetch_file "scripts/backup.sh"      "${SCRIPTS_DIR}/backup.sh"
  fetch_file "scripts/bandwidth.sh"   "${SCRIPTS_DIR}/bandwidth.sh"
  fetch_file "scripts/speedtest.sh"   "${SCRIPTS_DIR}/speedtest.sh"

  chmod +x "${SCRIPTS_DIR}/"*.sh
}

setup_command_menu() {
  # command 'menu' available globally
  ln -sf "${SCRIPTS_DIR}/menu.sh" /usr/local/sbin/menu
  ln -sf "${SCRIPTS_DIR}/menu.sh" /usr/local/bin/menu

  # ensure PATH for root includes /usr/local/sbin
  if [[ -f /root/.bashrc ]]; then
    if ! grep -q "/usr/local/sbin" /root/.bashrc; then
      echo 'export PATH="/usr/local/sbin:/usr/local/bin:$PATH"' >> /root/.bashrc
    fi
  fi

  # fallback profile
  if [[ -f /root/.profile ]]; then
    if ! grep -q "/usr/local/sbin" /root/.profile; then
      echo 'export PATH="/usr/local/sbin:/usr/local/bin:$PATH"' >> /root/.profile
    fi
  fi
}

post_info() {
  echo ""
  echo "✅ INSTALLED"
  echo "Command: menu"
  echo "Path   : ${WORKDIR}"
  echo ""
}

main() {
  need_root
  install_pkgs
  setup_files
  setup_command_menu
  hash -r || true
  post_info

  # auto open menu after install
  exec menu
}

main "$@"