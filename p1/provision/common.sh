#!/usr/bin/env bash
set -euo pipefail

PUBKEY_SRC="${1:-/tmp/host_id.pub}"

echo "[common] starting…"
if [[ ! -f "$PUBKEY_SRC" ]]; then
  echo "[common] ERROR: pubkey '$PUBKEY_SRC' not found" >&2
  exit 1
fi

# Ensure vagrant user has your host pubkey (append once)
install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
touch /home/vagrant/.ssh/authorized_keys
grep -qf "$PUBKEY_SRC" /home/vagrant/.ssh/authorized_keys || cat "$PUBKEY_SRC" >> /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/authorized_keys

# Basic deps
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl ca-certificates
echo "[common] done."

