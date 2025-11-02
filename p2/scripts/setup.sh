#!/bin/bash
#
# K3s Server Setup and Application Deployment Script
# Installs K3s and deploys the three applications with ingress

set -e
set -u
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting K3s server and application deployment on $(hostname)..."
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

# Wait for all system pods to be ready
log "Waiting for system pods to be ready..."
sudo kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=120s || true

log "Deploying applications..."
sudo kubectl apply -f /vagrant/confs/

# Wait for deployments to be ready
log "Waiting for deployments to be ready..."
sleep 5
sudo kubectl wait --for=condition=Available deployments --all --timeout=120s || true

log "Deployment complete!"
log ""
log "Cluster status:"
sudo kubectl get nodes -o wide
log ""
log "Deployments:"
sudo kubectl get deployments
log ""
log "Pods:"
sudo kubectl get pods
log ""
log "Services:"
sudo kubectl get svc
log ""
log "Ingress:"
sudo kubectl get ingress
log ""
log "Setup complete! Applications are ready."
