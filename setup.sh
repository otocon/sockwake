#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_USER="$USER"
TIMEOUT=30
while getopts "u:t:" opt; do
    case $opt in
        u) TARGET_USER="$OPTARG" ;;
        t) TIMEOUT="$OPTARG" ;;
        *) echo "Usage: $0 [-u username] [-t timeout_seconds]"; exit 1 ;;
    esac
done
TARGET_UID="$(id -u "$TARGET_USER")"

sed "s/{{USERNAME}}/$TARGET_USER/g; s/{{UID}}/$TARGET_UID/g; s/{{TIMEOUT}}/$TIMEOUT/g" \
    "$SCRIPT_DIR/mysql5ram.service" > /tmp/mysql5ram.service

sudo semanage port -a -t systemd_socket_proxyd_port_t -p tcp 3303 2>/dev/null || true

sudo cp "$SCRIPT_DIR"/mysql5ram.socket "$SCRIPT_DIR"/mysql5ram-proxy.service /tmp/mysql5ram.service /etc/systemd/system/
rm /tmp/mysql5ram.service
sudo systemctl daemon-reload
sudo systemctl enable --now mysql5ram.socket
