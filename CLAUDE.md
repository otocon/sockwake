# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mysql5ram is a systemd socket-activation setup that starts a MySQL 5 Docker container on-demand when a connection hits port 53303. The container stops automatically via `StopWhenUnneeded=true` once the proxy exits after 15 minutes of idle time.

## Architecture

```
Client (port 53303) → mysql5ram.socket → mysql5ram-proxy.service → mysql5ram.service (Docker)
```

1. **mysql5ram.socket** — listens on port 53303, triggers the proxy on first connection
2. **mysql5ram-proxy.service** — `systemd-socket-proxyd` forwarding 53303→127.0.0.1:3303, exits after 15min idle
3. **mysql5ram.service** — runs `docker start -a mysql5ram`, waits for `mysqladmin ping` readiness, then signals `systemd-notify --ready`. Sends desktop notifications (via D-Bus/notify-send) on start/stop

The Docker container must already exist with the name `mysql5ram` and expose MySQL on port 3303.

## Setup / Teardown

```bash
# Install (requires sudo); copies units to /etc/systemd/system/, adds SELinux port exception
./setup.sh                        # current user, 30s timeout
./setup.sh -u <user> -t <seconds> # custom user and startup timeout

# Uninstall (requires sudo); removes units and SELinux exception
./teardown.sh
```

`setup.sh` performs sed substitution on template variables (`{{USERNAME}}`, `{{UID}}`, `{{TIMEOUT}}`) in mysql5ram.service before copying.

## Key Details

- **Ports**: 53303 (external/socket) → 3303 (Docker container MySQL)
- **SELinux**: `semanage port` adds/removes tcp/3303 as `systemd_socket_proxyd_port_t`
- **Service type**: `Type=notify` with `NotifyAccess=all` — readiness is signaled only after `mysqladmin ping` succeeds
- **All files are bash scripts or systemd unit files** — no build system or tests
