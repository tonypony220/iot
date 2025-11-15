#!/usr/bin/env bash
set -euo pipefail

# Retrieve GitLab root password
PASSWORD=$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)

if [ -z "$PASSWORD" ]; then
    echo "Error: Cannot retrieve GitLab password. Is GitLab installed?" >&2
    exit 1
fi

echo "$PASSWORD"
