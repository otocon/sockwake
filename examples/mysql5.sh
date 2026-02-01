#!/bin/bash
# Migration example: recreate the original mysql5 setup using sockwake
#
# Prerequisites:
#   - Docker container named "mysql5" exists and exposes MySQL on port 3306
#   - Run as root (sudo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create the instance (equivalent to the old setup.sh)
"$SCRIPT_DIR/sockwake" create \
  --name mysql5 \
  --listen-port 53306 \
  --container-port 3306 \
  --container-name mysql5 \
  --startup-timeout 30 \
  --idle-timeout 15min

# To remove:
#   sockwake remove --name mysql5
