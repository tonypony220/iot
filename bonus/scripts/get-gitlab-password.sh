#!/usr/bin/env bash

set -e
set -u
set -o pipefail
kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d; echo
