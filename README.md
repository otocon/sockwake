# mysql5ram

Systemd socket-activation setup that starts a MySQL 5 Docker container on-demand when a connection hits port 53303.

## Known limitation: initial connection delay

Because of how systemd socket activation works, the kernel completes the TCP handshake immediately when a client connects to port 53303, but the connection sits idle in the kernel's listen queue while the full activation chain starts (proxy -> Docker -> MySQL). No application-level data flows until the proxy is running and calls `accept()`.

This means clients that expect a prompt MySQL greeting packet (e.g. JDBC / HikariCP) may time out waiting, even though TCP reports the connection as established.

**Workaround for Spring Boot / HikariCP:** set `initializationFailTimeout=-1` for lazy pool initialization, or set it to a value larger than the worst-case startup time.

## References

- [Integration of a Go service with systemd: socket activation](https://vincent.bernat.ch/en/blog/2018-systemd-golang-socket-activation) - Explains how incoming connections sit in the kernel listen queue while a socket-activated service is starting: *"new connections are not accepted: they sit in the listen queue associated to the socket."*
- [systemd.socket man page](https://www.freedesktop.org/software/systemd/man/latest/systemd.socket.html) - Documents the `Backlog=` directive (default 128) controlling the kernel listen queue size during the startup window.
- [systemd#2105: systemd-socket-proxyd does not wait for socket to be ready](https://github.com/systemd/systemd/issues/2105) - Discussion of `systemd-socket-proxyd` having no retry logic when connecting to the backend.
