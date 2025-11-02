#!/bin/bash
#
# K3s Agent Setup Script
# Installs K3s in agent mode and joins the server cluster

set -e
set -u
set -o pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting K3s agent setup on $(hostname)..."
log "Server IP: ${SERVER_IP}"
log "Worker IP: ${WORKER_IP}"

# Check if K3s is already installed
if [ -f /usr/local/bin/k3s ]; then
    log "K3s is already installed, skipping installation"
    exit 0
fi

# Wait for token file from server
log "Waiting for server token..."
TOKEN_FILE="${SHARED_TOKEN_PATH}"
MAX_ATTEMPTS=30
ATTEMPT=0

while [ ! -f "${TOKEN_FILE}" ]; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ ${ATTEMPT} -ge ${MAX_ATTEMPTS} ]; then
        log "ERROR: Token file not found after $((MAX_ATTEMPTS * 10)) seconds"
        log "Server may not have finished provisioning"
        exit 1
    fi
    log "Waiting for token... (attempt ${ATTEMPT}/${MAX_ATTEMPTS})"
    sleep 10
done

log "Token file found, reading token..."
K3S_TOKEN=$(cat "${TOKEN_FILE}")

if [ -z "${K3S_TOKEN}" ]; then
    log "ERROR: Token is empty"
    exit 1
fi

log "Installing K3s in agent mode..."
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="${K3S_TOKEN}" sh -s - \
    --node-ip "${WORKER_IP}" \
    --flannel-iface eth1

log "K3s agent installation complete"

# Wait for agent to be ready
log "Waiting for agent to connect..."
sleep 10

log "Agent setup complete!"
