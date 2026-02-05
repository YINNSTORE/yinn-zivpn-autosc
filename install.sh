#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="YINNSTORE"
GITHUB_REPO="yinn-zivpn-autosc"
BRANCH="main"

REPO_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${BRANCH}"
WORKDIR="/usr/local/yinn-zivpn"

mkdir -p "$WORKDIR/scripts"

fetch() {
  local f="$1"
  curl -fsSL "${REPO_RAW_BASE}/scripts/${f}" -o "${WORKDIR}/scripts/${f}"
}

fetch "menu.sh"
fetch "core_install.sh"
fetch "user_manager.sh"
fetch "settings.sh"
fetch "backup.sh"
fetch "bandwidth.sh"
fetch "speedtest.sh"

chmod +x "$WORKDIR/scripts/"*.sh

bash "$WORKDIR/scripts/menu.sh"