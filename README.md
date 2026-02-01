# sockwake

A single-file Python 3 CLI tool that creates, removes, and lists systemd socket-activated Docker container wrappers. No external dependencies — stdlib only.

## How it works

```
Client (listen-port) → name.socket → name-proxy.service → name.service (Docker)
```

1. **name.socket** — listens on the configured port, triggers the proxy on first connection
2. **name-proxy.service** — `systemd-socket-proxyd` forwards traffic to the container port, exits after idle timeout
3. **name.service** — runs `docker start -a`, waits for health check, signals readiness via `systemd-notify`

The Docker container must already exist. The tool generates and installs all three systemd units.

## Usage

### Create an instance

```bash
sudo ./sockwake create \
    --name mysql5ram \
    --listen-port 53303 \
    --container-port 3303 \
    --container-name mysql5ram
```

Optional flags:
- `--startup-timeout 30` — seconds before systemd gives up starting (default: 30)
- `--idle-timeout 15min` — time before proxy exits on idle (default: 15min)
- `--health-check "CMD"` — custom health check (`{container_port}` is substituted); `none` to disable
- `--no-notifications` — disable desktop notifications
- `--user USERNAME` — user for notifications (default: `$SUDO_USER` or `$USER`)
- `--no-selinux` — skip SELinux port labeling
- `--dry-run` — print generated units to stdout without installing
- `--force` — overwrite existing units

### Remove an instance

```bash
sudo ./sockwake remove --name mysql5ram
# or remove all managed instances:
sudo ./sockwake remove --all
```

### List instances

```bash
sudo ./sockwake list
sudo ./sockwake list --json
```

### Show detailed status

```bash
sudo ./sockwake status --name mysql5ram
```

## Service identification

All generated unit files include `X-ManagedBy=sockwake` and `X-InstanceConfig={...}` (JSON) in the `[Unit]` section. The `list` command discovers instances by scanning for these markers — no separate registry file needed.

## Known limitation: initial connection delay

Because of how systemd socket activation works, the kernel completes the TCP handshake immediately when a client connects, but the connection sits idle in the kernel's listen queue while the full activation chain starts (proxy -> Docker -> application). No application-level data flows until the proxy is running and calls `accept()`.

Clients that expect a prompt greeting packet (e.g. JDBC / HikariCP for MySQL) may time out waiting, even though TCP reports the connection as established.

**Workaround for Spring Boot / HikariCP:** set `initializationFailTimeout=-1` for lazy pool initialization, or set it to a value larger than the worst-case startup time.

## Alternatives

- [Podman socket activation](https://github.com/containers/podman/blob/main/docs/tutorials/socket_activation.md#socket-activation-of-containers) — Podman has native support for socket-activating containers, where the container receives the socket file descriptor directly. This avoids the proxy layer entirely but requires Podman and a container image that supports socket activation via `$LISTEN_FDS`.

## References

- [Integration of a Go service with systemd: socket activation](https://vincent.bernat.ch/en/blog/2018-systemd-golang-socket-activation) — explains how incoming connections sit in the kernel listen queue while a socket-activated service is starting
- [systemd.socket man page](https://www.freedesktop.org/software/systemd/man/latest/systemd.socket.html) — documents the `Backlog=` directive (default 128) controlling the kernel listen queue size
- [systemd#2105: systemd-socket-proxyd does not wait for socket to be ready](https://github.com/systemd/systemd/issues/2105) — discussion of `systemd-socket-proxyd` having no retry logic
