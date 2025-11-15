# K3D Configuration
CLUSTER_NAME ?= demo
API_PORT ?= 6445
HTTP_PORT ?= 8080
APP_PORT ?= 8888


# Export all variables for scripts
export CLUSTER_NAME
export API_PORT
export HTTP_PORT
export APP_PORT

all: up

check-k3d:
	@command -v k3d >/dev/null 2>&1 || { echo "ERROR: k3d not installed. Run 'make install'"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "ERROR: kubectl not installed. Run 'make install'"; exit 1; }

up: check-k3d
	@echo "Creating K3D cluster '$(CLUSTER_NAME)'..."
	./scripts/setup.sh
	@echo ""
	@echo "Cluster created successfully!"
	@echo "Waiting for Argo CD to be ready..."
	@sleep 5
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s 2>/dev/null || true
	@echo ""
	@echo "Setup complete!"
	@echo "Run 'make argocd-ui' to get access information"
	@echo "Run 'make status' to check deployment status"

down:
	@echo "Stopping K3D cluster..."
	k3d cluster stop $(CLUSTER_NAME) 2>/dev/null || echo "Cluster not running"

start:
	@echo "Starting K3D cluster..."
	k3d cluster start $(CLUSTER_NAME) 2>/dev/null || echo "Cluster doesn't exist. Run 'make up' first"

status:
	@echo "=== K3D Cluster Status ==="
	@k3d cluster list | grep $(CLUSTER_NAME) || echo "Cluster '$(CLUSTER_NAME)' not found"
	@echo ""
	@echo "=== Kubernetes Nodes ==="
	@kubectl get nodes -o wide 2>/dev/null || echo "Cannot connect to cluster"
	@echo ""
	@echo "=== Namespaces ==="
	@kubectl get namespaces | grep -E "NAME|argocd|dev" 2>/dev/null || echo "Cannot get namespaces"
	@echo ""
	@echo "=== Argo CD Pods ==="
	@kubectl get pods -n argocd 2>/dev/null || echo "Cannot get Argo CD pods"
	@echo ""
	@echo "=== Application in dev namespace ==="
	@kubectl get all -n dev 2>/dev/null || echo "Cannot get dev namespace resources"
	@echo ""
	@echo "=== Argo CD Applications ==="
	@kubectl get applications -n argocd 2>/dev/null || echo "Cannot get Argo CD applications"

argocd-ui:
	@echo "=== Argo CD Access Information ==="
	@echo ""
	@echo "URL: http://argocd.127.0.0.1.nip.io:${HTTP_PORT}"
	@echo "Username: admin"
	@echo -n "Password: "
	@./scripts/get-argocd-password.sh 2>/dev/null || echo "Cannot retrieve password"

test:
	@./scripts/test.sh

clean:
	@echo "Deleting K3D cluster '$(CLUSTER_NAME)'..."
	k3d cluster delete $(CLUSTER_NAME) 2>/dev/null || echo "Cluster already deleted"
	@echo "Cleanup complete!"

.PHONY: help check-k3d install up down start status argocd-ui test clean
