#!/bin/bash
sudo systemctl disable --now mysql5ram.socket
sudo systemctl stop mysql5ram-proxy.service
sudo systemctl stop mysql5ram.service
sudo rm -f /etc/systemd/system/mysql5ram.socket /etc/systemd/system/mysql5ram-proxy.service /etc/systemd/system/mysql5ram.service
sudo systemctl daemon-reload
sudo semanage port -d -t systemd_socket_proxyd_port_t -p tcp 3303 2>/dev/null || true
