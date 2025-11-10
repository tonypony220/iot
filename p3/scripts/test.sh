#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

success() {
    echo "[OK] $*"
}

error() {
    echo "[ERROR] $*"
}

warning() {
    echo "[WARNING] $*"
}

log "Starting P3 validation tests..."
echo ""

# Test 1: Check if k3d cluster exists
log "Test 1: Checking K3D cluster..."
if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
    success "K3D cluster '${CLUSTER_NAME}' exists"
else
    error "K3D cluster '${CLUSTER_NAME}' not found"
    exit 1
fi
echo ""

# Test 2: Check if kubectl can connect
log "Test 2: Checking kubectl connection..."
if kubectl cluster-info >/dev/null 2>&1; then
    success "kubectl can connect to cluster"
else
    error "kubectl cannot connect to cluster"
    exit 1
fi
echo ""

# Test 3: Check namespaces
log "Test 3: Checking namespaces..."
NAMESPACES=$(kubectl get namespaces -o name 2>/dev/null || echo "")
if echo "$NAMESPACES" | grep -q "namespace/argocd"; then
    success "Namespace 'argocd' exists"
else
    error "Namespace 'argocd' not found"
    exit 1
fi

if echo "$NAMESPACES" | grep -q "namespace/dev"; then
    success "Namespace 'dev' exists"
else
    error "Namespace 'dev' not found"
    exit 1
fi
echo ""

# Test 4: Check Argo CD pods
log "Test 4: Checking Argo CD pods..."
ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
if [ "$ARGOCD_PODS" -gt 0 ]; then
    success "Found $ARGOCD_PODS Argo CD pods"

    # Check if all are running
    NOT_RUNNING=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -v "Running" | wc -l)
    if [ "$NOT_RUNNING" -eq 0 ]; then
        success "All Argo CD pods are running"
    else
        warning "$NOT_RUNNING Argo CD pods are not in Running state"
    fi
else
    error "No Argo CD pods found in argocd namespace"
    exit 1
fi
echo ""

# Test 5: Check Argo CD Application
log "Test 5: Checking Argo CD Application..."
if kubectl get application -n argocd will-playground >/dev/null 2>&1; then
    success "Application 'will-playground' exists"

    # Check sync status
    SYNC_STATUS=$(kubectl get application -n argocd will-playground -o jsonpath='{.status.sync.status}' 2>/dev/null)
    if [ "$SYNC_STATUS" = "Synced" ]; then
        success "Application is synced"
    else
        warning "Application sync status: $SYNC_STATUS"
    fi

    # Check health status
    HEALTH_STATUS=$(kubectl get application -n argocd will-playground -o jsonpath='{.status.health.status}' 2>/dev/null)
    if [ "$HEALTH_STATUS" = "Healthy" ]; then
        success "Application is healthy"
    else
        warning "Application health status: $HEALTH_STATUS"
    fi
else
    error "Application 'will-playground' not found"
    exit 1
fi
echo ""

# Test 6: Check application pods in dev namespace
log "Test 6: Checking application pods in dev namespace..."
DEV_PODS=$(kubectl get pods -n dev --no-headers 2>/dev/null | wc -l)
if [ "$DEV_PODS" -gt 0 ]; then
    success "Found $DEV_PODS pod(s) in dev namespace"

    # Check if running
    RUNNING_PODS=$(kubectl get pods -n dev --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$RUNNING_PODS" -gt 0 ]; then
        success "$RUNNING_PODS pod(s) are running"
    else
        warning "No pods are in Running state"
    fi
else
    warning "No pods found in dev namespace (may still be deploying)"
fi
echo ""

# Test 7: Check deployment image version
log "Test 7: Checking deployment configuration..."
IMAGE=$(kubectl get deployment -n dev -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
if [ -n "$IMAGE" ]; then
    success "Application image: $IMAGE"
else
    warning "Could not retrieve deployment image"
fi
echo ""

# Test 8: Check Argo CD admin secret
log "Test 8: Checking Argo CD admin secret..."
if kubectl get secret -n argocd argocd-initial-admin-secret >/dev/null 2>&1; then
    success "Argo CD admin secret exists"
else
    error "Argo CD admin secret not found"
fi
echo ""

# Test 9: Check ingress configuration
log "Test 9: Checking ingress configuration..."
INGRESSES=$(kubectl get ingress -n argocd --no-headers 2>/dev/null | wc -l)
if [ "$INGRESSES" -gt 0 ]; then
    success "Found $INGRESSES ingress(es) in argocd namespace"
else
    warning "No ingresses found (Argo CD may not be accessible via HTTP)"
fi
echo ""

# Test 10: Try to access application (if service exists)
log "Test 10: Checking service accessibility..."
SERVICE_EXISTS=$(kubectl get svc -n dev --no-headers 2>/dev/null | wc -l)
if [ "$SERVICE_EXISTS" -gt 0 ]; then
    success "Found service(s) in dev namespace"

    # Try to curl the application
    if curl -s --connect-timeout 5 http://localhost:${HTTP_PORT} >/dev/null 2>&1; then
        success "Application is accessible on http://localhost:${HTTP_PORT}"
    else
        warning "Cannot access application on http://localhost:${HTTP_PORT} (may need port forwarding or time to start)"
    fi
else
    warning "No services found in dev namespace"
fi
echo ""

# Summary
log "=== Validation Summary ==="
echo ""
echo "All critical checks passed! ✓"
echo ""
echo "Next steps:"
echo "  1. Access Argo CD UI at: http://localhost:${ARGO_PORT}"
echo "  2. Username: admin"
echo "  3. Get password: ./scripts/get-argocd-password.sh"
echo "  4. Check application at: http://localhost:${HTTP_PORT}"
echo ""
log "Validation complete!"
