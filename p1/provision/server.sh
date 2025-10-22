#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${1:?usage: server.sh <SERVER_IP>}"

echo "[server] installing k3s server on ${SERVER_IP}…"

export INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} \
  --advertise-address=${SERVER_IP} \
  --write-kubeconfig-mode=644 \
  --disable servicelb --disable traefik"

curl -sfL https://get.k3s.io | sh -

echo "[server] waiting for node-token…"
for i in {1..120}; do
  [[ -f /var/lib/rancher/k3s/server/node-token ]] && break
  sleep 2
done
if [[ ! -f /var/lib/rancher/k3s/server/node-token ]]; then
  echo "[server] ERROR: node-token not found after timeout" >&2
  systemctl status k3s --no-pager || true
  journalctl -u k3s --no-pager -n 200 || true
  exit 1
fi

cp /var/lib/rancher/k3s/server/node-token /vagrant/k3s_token

# Make a kubeconfig that points to SERVER_IP, not 127.0.0.1
if [[ -f /etc/rancher/k3s/k3s.yaml ]]; then
  sed "s/127.0.0.1/${SERVER_IP}/g" /etc/rancher/k3s/k3s.yaml > /vagrant/kubeconfig
  chmod 600 /vagrant/kubeconfig
fi

echo "[server] k3s server ready."

