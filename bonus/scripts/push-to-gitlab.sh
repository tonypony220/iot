#!/usr/bin/env bash
set -euo pipefail

# Configuration
# GIT_HOST uses nip.io for automatic DNS resolution to 127.0.0.1
# This allows GitLab to work with a proper domain name without /etc/hosts configuration
GIT_HOST="gitlab.127.0.0.1.nip.io:8080"
PROJECT="root/apending_iot.git"
REMOTE_URL="http://${GIT_HOST}/${PROJECT}"
NAMESPACE="gitlab"
USER="root"

echo "  → Pushing manifests to GitLab..."

# Get GitLab root password
PASS="$(kubectl -n "${NAMESPACE}" get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d)"

# Configure git credentials
git config --global credential.helper store
printf "http://%s:%s@%s\n" "$USER" "$PASS" "$GIT_HOST" > ~/.git-credentials
chmod 600 ~/.git-credentials

# Ensure Git never tries to prompt in scripts
export GIT_TERMINAL_PROMPT=0

# Set remote and push
git remote remove origin 2>/dev/null || true
git remote add origin "${REMOTE_URL}"
git push -u origin HEAD 2>&1 | grep -v "password" || true

echo "  ✓ Manifests pushed to GitLab"
