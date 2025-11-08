#!/bin/bash

set -e
set -u
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting K3s server setup on $(hostname)..."
log "Server IP: ${SERVER_IP}"

# Check if K3s is already installed
if [ -f /usr/local/bin/k3s ]; then
    log "K3s is already installed, skipping installation"
else
    log "Installing K3s in server mode..."
    curl -sfL https://get.k3s.io | sh -s - server \
        --write-kubeconfig-mode 644 \
        --node-ip "${SERVER_IP}" \
        --flannel-iface eth1 \
        --bind-address "${SERVER_IP}" \
        --advertise-address "${SERVER_IP}"

    log "K3s server installation complete"
fi

# Wait for K3s to be ready
log "Waiting for K3s to be ready..."
until sudo kubectl get nodes >/dev/null 2>&1; do
    log "Waiting for K3s API server..."
    sleep 2
done
log "K3s is ready"

# Wait for node token to be available
log "Waiting for node token..."
TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"
TIMEOUT=60
ELAPSED=0

while [ ! -f "${TOKEN_FILE}" ]; do
    if [ ${ELAPSED} -ge ${TIMEOUT} ]; then
        log "ERROR: Token file not found after ${TIMEOUT} seconds"
        exit 1
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

log "Node token found, exporting to shared folder..."
sudo cp "${TOKEN_FILE}" "${SHARED_TOKEN_PATH}"
sudo chmod 644 "${SHARED_TOKEN_PATH}"

log "Server setup complete!"
log "Node status:"
sudo kubectl get nodes -o wide
