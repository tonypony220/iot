#!/usr/bin/env bash
set -euo pipefail

# This script creates a Kubernetes Secret that allows ArgoCD to authenticate
# with the internal GitLab repository.
#
# What it does:
# 1. Gets GitLab's auto-generated password from Kubernetes
# 2. Creates a secret containing: GitLab URL, username, and password
# 3. Applies the secret to the argocd namespace
# 4. ArgoCD automatically discovers it (via special label) and uses it to
#    authenticate when pulling manifests from GitLab
#
# Why needed:
# - GitLab is password-protected
# - ArgoCD needs credentials to access the Git repository
# - Password is dynamically generated on each GitLab installation
# ============================================================================

# Configuration
NAMESPACE="gitlab"        # Where GitLab is installed
USER="root"              # GitLab username
ARGO_NS="argocd"         # Where ArgoCD is installed (where secret goes)

echo "  → Creating ArgoCD repository secret..."

# Secret details
SECRET_NAME="repo-gitlab-apending-iot-http"
# Internal cluster DNS - ArgoCD talks to GitLab using Kubernetes service DNS
REPO_URL="http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/apending_iot.git"

# Get GitLab root password dynamically from Kubernetes
# GitLab Helm chart creates this secret automatically with a random password
# We retrieve it, extract the password field, and decode from base64
PASS="$(kubectl -n "${NAMESPACE}" get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d)"

# Create a temporary YAML file with the secret definition
# This will be applied to Kubernetes and then deleted
cat > /tmp/${SECRET_NAME}.yaml <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${ARGO_NS}
  labels:
    # IMPORTANT: This special label tells ArgoCD to use this secret for Git authentication
    # ArgoCD scans for secrets with this label and automatically uses them
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  # stringData: Kubernetes automatically base64-encodes these values
  url: ${REPO_URL}        # GitLab repository URL (internal cluster DNS)
  username: ${USER}       # GitLab username (root)
  password: ${PASS}       # GitLab password (retrieved dynamically)
YAML

# Apply the secret to Kubernetes
# This creates the secret in the argocd namespace
kubectl apply -f /tmp/${SECRET_NAME}.yaml

rm -f /tmp/${SECRET_NAME}.yaml

echo "  ✓ ArgoCD secret created"
