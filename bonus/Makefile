# K3D Configuration
CLUSTER_NAME ?= demo
API_PORT ?= 6445
HTTP_PORT ?= 8080
ARGO_PORT ?= 8888
GITLAB_PORT ?= 8181

# Export all variables for scripts
export CLUSTER_NAME
export API_PORT
export HTTP_PORT
export ARGO_PORT
export GITLAB_PORT

all: check-deps up info

check-deps:
	@echo "[✓] Checking dependencies..."
	@command -v k3d >/dev/null 2>&1 || { echo "[✗] k3d not installed"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "[✗] kubectl not installed"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "[✗] helm not installed"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "[✗] git not installed"; exit 1; }
	@echo "[✓] All dependencies found"

up: check-deps
	@./scripts/install.sh

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
	@kubectl get namespaces | grep -E "NAME|argocd|gitlab|dev" 2>/dev/null || echo "Cannot get namespaces"
	@echo ""
	@echo "=== Argo CD Pods ==="
	@kubectl get pods -n argocd 2>/dev/null || echo "Cannot get Argo CD pods"
	@echo ""
	@echo "=== Gitlab Pods ==="
	@kubectl get pods -n gitlab 2>/dev/null || echo "Cannot get gitlab pods"
	@echo ""
	@echo "=== Application in dev namespace ==="
	@kubectl get all -n dev 2>/dev/null || echo "Cannot get dev namespace resources"
	@echo ""
	@echo "=== Argo CD Applications ==="
	@kubectl get applications -n argocd 2>/dev/null || echo "Cannot get Argo CD applications"
	@echo ""
	@echo "=== Gitlab Applications ==="
	@kubectl get applications -n gitlab 2>/dev/null || echo "Cannot get Gitlab applications"

info:
	@echo ""
	@echo "════════════════════════════════════════"
	@echo "ACCESS INFORMATION"
	@echo "════════════════════════════════════════"
	@echo ""
	@echo "GitLab:  http://localhost:$(GITLAB_PORT)"
	@echo "  User:  root"
	@echo -n "  Pass:  "
	@./scripts/get-gitlab-password.sh 2>/dev/null || echo "Cannot retrieve password"
	@echo ""
	@echo "ArgoCD:  http://localhost:$(ARGO_PORT)"
	@echo "  User:  admin"
	@echo -n "  Pass:  "
	@./scripts/get-argocd-password.sh 2>/dev/null || echo "Cannot retrieve password"
	@echo ""
	@echo "App:     http://localhost:$(HTTP_PORT)"
	@echo ""
	@echo "To test v1→v2: Edit bonus/confs/manifests/wii.yaml,"
	@echo "               commit & push to GitLab, watch ArgoCD sync"
	@echo ""

logs-argocd:
	@echo "=== ArgoCD Server Logs ==="
	@kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50

logs-gitlab:
	@echo "=== GitLab Webservice Logs ==="
	@kubectl logs -n gitlab -l app=webservice --tail=50

clean:
	@echo "Deleting K3D cluster '$(CLUSTER_NAME)'..."
	@k3d cluster delete $(CLUSTER_NAME) 2>/dev/null || echo "Cluster already deleted"
	@echo "Cleanup complete!"

.PHONY: all check-deps up down start status info logs-argocd logs-gitlab clean
