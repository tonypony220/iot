#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting K3D cluster setup..."

# Check if cluster already exists
if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
	log "Cluster '${CLUSTER_NAME}' already exists. Deleting and recreating..."
	k3d cluster delete "${CLUSTER_NAME}"
fi

# Create a single-node cluster
# --agents 1 adds one worker (optional but realistic)
# -p/--port exposes Service LB ports via the k3d-proxy container
# --api-port pins the host port for the Kubernetes API (6443 inside cluster)
log "Creating k3d cluster '${CLUSTER_NAME}'..."
k3d cluster create "${CLUSTER_NAME}" \
  --servers 1 --agents 1 \
  --api-port "${API_PORT}" \
  -p "${HTTP_PORT}:80@loadbalancer" \
  --port "${ARGO_PORT}:${ARGO_PORT}@loadbalancer"

log "Cluster created successfully"

# Point kubectl at this new cluster (k3d creates/updates the kubeconfig)
kubectl cluster-info

# System namespace for Argo CD components
log "Creating namespaces..."
kubectl create namespace argocd
kubectl create namespace dev
log "Namespaces created: argocd, dev"

# Install the official Argo CD bundle (CRDs + controllers + API/UI server)
log "Installing Argo CD in argocd namespace..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD server deployment to be available
log "Waiting for Argo CD server to be deployed..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true

# Disable TLS on the Argo CD server to make it accessible via HTTP
log "Configuring Argo CD server (disabling TLS)..."
kubectl -n argocd patch deploy argocd-server \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

log "Applying Argo CD application and ingress configurations..."
kubectl apply -f confs/argocd-app.yaml
kubectl apply -f confs/argo-ingress.yaml

# Display Argo CD pods status
log "Argo CD pods status:"
kubectl get pods -n argocd

log "Setup complete!"
log ""
log "Access Argo CD UI at: http://localhost:${ARGO_PORT}"
log "Username: admin"
log "Get password with: ./scripts/get-argocd-password.sh"
