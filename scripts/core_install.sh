#!/bin/bash
set -euo pipefail
clear

BASE="/etc/yinn-zivpn"
BIN="/usr/local/bin/zivpn"
mkdir -p "$BASE" >/dev/null 2>&1

pause(){ read -rp "Enter untuk lanjut..." _; }

apt-get update -y
apt-get install -y curl jq openssl ca-certificates iproute2 net-tools vnstat >/dev/null 2>&1 || true
timedatectl set-timezone Asia/Jakarta >/dev/null 2>&1 || true

echo "=== INSTALL CORE ZIVPN (YinnStore) ==="
read -rp "Domain (wajib): " d
if [[ -z "${d:-}" ]]; then echo "Domain kosong."; pause; exit 0; fi

def="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
read -rp "Core URL (Enter=default): " url
[[ -z "${url:-}" ]] && url="$def"

echo "Download core..."
curl -fsSL "$url" -o "$BIN"
chmod +x "$BIN"

echo "$d" > "$BASE/domain"

echo "Write config..."
cat > "$BASE/config.json" <<'EOF'
{
  "listen": ":5667",
  "server_name": "ZiVPN",
  "log_level": "info"
}
EOF

echo "Generate SSL self-signed..."
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/C=ID/ST=JawaBarat/L=Jampang/O=YinnStore/OU=ZiVPN/CN=${d}" \
  -keyout "$BASE/zivpn.key" -out "$BASE/zivpn.crt" >/dev/null 2>&1

echo "Write systemd..."
cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZiVPN UDP Core (YinnStore)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$BASE
ExecStart=$BIN server -c $BASE/config.json
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

echo "✅ Core installed & running."
pause