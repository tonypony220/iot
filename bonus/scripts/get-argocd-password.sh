#!/usr/bin/env bash
set -euo pipefail

# Retrieve Argo CD admin password
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)

if [ -z "$PASSWORD" ]; then
    echo "Error: Cannot retrieve ArgoCD password. Is the cluster running?" >&2
    exit 1
fi

echo "$PASSWORD"
