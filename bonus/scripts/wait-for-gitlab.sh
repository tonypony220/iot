#!/usr/bin/env bash
set -euo pipefail

# Configuration
# Using nip.io (wildcard DNS service) for automatic domain resolution
# gitlab.127.0.0.1.nip.io automatically resolves to 127.0.0.1
# This eliminates the need for /etc/hosts configuration
GIT_HOST="gitlab.127.0.0.1.nip.io:8080"
NAMESPACE="gitlab"

echo ""
echo "Waiting for GitLab to be ready (this may take 2-3 minutes)..."

# Wait for the password secret to exist
echo "  → Waiting for GitLab password secret..."
RETRIES=30
until kubectl -n "${NAMESPACE}" get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' >/dev/null 2>&1; do
    (( RETRIES-- )) || { echo "  ✗ GitLab secret not created in time"; exit 1; }
    sleep 5
done
echo "  ✓ GitLab password secret ready"

# Wait for GitLab webservice pods to be running
echo "  → Waiting for GitLab pods to be ready..."
kubectl wait --for=condition=ready pod -l app=webservice -n gitlab --timeout=600s

# Wait for GitLab readiness endpoint
echo "  → Waiting for GitLab API to respond..."
RETRIES=90
until curl -fsS "http://${GIT_HOST}/-/readiness?all=1" >/dev/null 2>&1; do
    (( RETRIES-- )) || { echo "  ✗ GitLab API did not become ready in time"; exit 1; }
    sleep 10
done

# Confirm health
curl -fsS "http://${GIT_HOST}/-/health" >/dev/null 2>&1
echo "  ✓ GitLab is fully ready"
