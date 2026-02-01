# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

sockwake is a single-file Python 3 CLI tool (stdlib only, no external deps) that creates, removes, and lists systemd socket-activated Docker container wrappers. Any Docker container can be made on-demand: it starts when a connection hits the configured port and stops automatically after idle timeout.

## Architecture

```
Client (listen-port) → name.socket → name-proxy.service → name.service (Docker)
```

1. **name.socket** — listens on the configured port, triggers the proxy on first connection
2. **name-proxy.service** — `systemd-socket-proxyd` forwards traffic to the container port, exits after idle timeout
3. **name.service** — runs `docker start -a`, waits for health check readiness, then signals `systemd-notify --ready`. Optionally sends desktop notifications on start/stop

The Docker container must already exist. The tool generates and installs all three systemd units.

## File Structure

```
sockwake    # Main CLI (Python 3, executable, single file)
README.md
CLAUDE.md
examples/
  mysql5ram.sh      # Migration example from the old bash setup
```

Templates are embedded as string constants in the script — no separate template files.

## CLI Commands

```bash
# Create instance (requires sudo)
sudo ./sockwake create --name NAME --listen-port PORT --container-port PORT --container-name CONTAINER

# Remove instance
sudo ./sockwake remove --name NAME
sudo ./sockwake remove --all

# List instances
sudo ./sockwake list [--json]

# Status of one instance
sudo ./sockwake status --name NAME
```

## Key Details

- **Service identification**: all generated units include `X-ManagedBy=sockwake` and `X-InstanceConfig={...}` (JSON) in `[Unit]` — no separate registry file
- **SELinux**: auto-detected; `semanage port` adds/removes the container port as `systemd_socket_proxyd_port_t`
- **Service type**: `Type=notify` with `NotifyAccess=all` — readiness signaled after health check succeeds
- **Binary paths**: resolved at generation time via `shutil.which()` with hardcoded fallbacks
- **Single file, Python 3 stdlib only** — no build system, no external dependencies, no tests
