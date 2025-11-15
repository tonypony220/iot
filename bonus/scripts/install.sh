#!/usr/bin/env bash
set -euo pipefail

# Configuration
NAMESPACE="gitlab"
ARGO_NS="argocd"
DEV_NS="dev"

echo ""
echo "════════════════════════════════════════"
echo "  Starting Infrastructure Setup"
echo "════════════════════════════════════════"

# Create K3d cluster
echo ""
echo "Creating K3d cluster..."
k3d cluster create ${CLUSTER_NAME:-demo} \
  --servers 1 --agents 2 \
  --api-port ${API_PORT:-6445} \
  -p "${HTTP_PORT:-8080}:80@loadbalancer" \
  -p "${ARGO_PORT:-8888}:8888@loadbalancer" \
  -p "${GITLAB_PORT:-8181}:8181@loadbalancer"
echo "  ✓ K3d cluster created"

# Create namespaces
echo ""
echo "Creating namespaces..."
kubectl create namespace ${ARGO_NS}
kubectl create namespace ${DEV_NS}
kubectl create namespace ${NAMESPACE}
echo "  ✓ Namespaces created (argocd, dev, gitlab)"

# Install ArgoCD
echo ""
echo "Installing ArgoCD..."
kubectl apply -n ${ARGO_NS} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "  → Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n ${ARGO_NS} --timeout=300s 2>/dev/null || true

echo "  → Patching ArgoCD for insecure mode..."
kubectl -n ${ARGO_NS} patch deploy argocd-server \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

sleep 5
kubectl wait --for=condition=available deployment/argocd-server -n ${ARGO_NS} --timeout=300s 2>/dev/null || true
echo "  ✓ ArgoCD installed"

# Apply ArgoCD ingress
echo ""
echo "Applying ArgoCD ingress..."
kubectl apply -f confs/argo-ingress.yaml
echo "  ✓ ArgoCD ingress applied"

# Install GitLab
echo ""
echo "Installing GitLab via Helm..."
helm repo add gitlab https://charts.gitlab.io >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

# Create backup secret stub
kubectl -n ${NAMESPACE} create secret generic gitlab-backup-empty \
  --from-literal=config=$'[default]\naccess_key=\nsecret_key=\nuse_https = False\n' 2>/dev/null || true

helm upgrade --install gitlab gitlab/gitlab \
  --namespace ${NAMESPACE} \
  -f confs/gitlab-values.yaml

echo "  ✓ GitLab installation started"

# Wait for GitLab
./scripts/wait-for-gitlab.sh

# Configure ArgoCD secret for GitLab
echo ""
echo "Configuring ArgoCD..."
./scripts/create-argocd-secret.sh
kubectl apply -f confs/argocd-app.yaml
echo "  ✓ ArgoCD application configured"

# Push manifests to GitLab
echo ""
./scripts/push-to-gitlab.sh

echo ""
echo "════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════"
echo ""
echo "Run 'make info' to see access information"
