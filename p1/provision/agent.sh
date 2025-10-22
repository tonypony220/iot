#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${1:?usage: agent.sh <SERVER_IP> <AGENT_IP>}"
AGENT_IP="${2:?usage: agent.sh <SERVER_IP> <AGENT_IP>}"

echo "[agent] waiting for /vagrant/k3s_token from server…"
for i in {1..120}; do
  [[ -f /vagrant/k3s_token ]] && break
  sleep 2
done
if [[ ! -f /vagrant/k3s_token ]]; then
  echo "[agent] ERROR: token file not found; is the server up?" >&2
  exit 1
fi

TOKEN="$(cat /vagrant/k3s_token)"
if [[ -z "$TOKEN" ]]; then
  echo "[agent] ERROR: token file is empty" >&2
  exit 1
fi

echo "[agent] installing k3s agent (node-ip ${AGENT_IP}, server https://${SERVER_IP}:6443)…"
export INSTALL_K3S_EXEC="agent --server https://${SERVER_IP}:6443 --token ${TOKEN} --node-ip=${AGENT_IP}"
curl -sfL https://get.k3s.io | sh -

echo "[agent] k3s agent started."

