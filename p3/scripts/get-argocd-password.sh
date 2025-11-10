#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Retrieve Argo CD admin password
kubectl -n argocd \
  get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d
echo
