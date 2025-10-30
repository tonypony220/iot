#!/usr/bin/env bash

install_k3d() {
	# Install k3d (tiny Kubernetes-in-Docker). Easier & faster than full K8s for a demo.
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

#sudo k3d cluster delete demo
setup() {

# Create a single-node cluster named "demo".
# --agents 1 adds one worker (optional but realistic).
# We also map HTTP 80 of the cluster LB to localhost:8888 so it's easy to reach apps later.
# -p/--port exposes Service LB ports via the k3d-proxy container
# --api-port pins the host port for the Kubernetes API (6443 inside cluster)
k3d cluster create demo \
  --servers 1 --agents 1 \
  --api-port 6445 \
      -p "8080:80@loadbalancer" \
  --port "8888:8888@loadbalancer"

# Point kubectl at this new cluster (k3d creates/updates the kubeconfig for you).
kubectl cluster-info

# System namespace for Argo CD components.
kubectl create namespace argocd

# Application namespace where your app Pods/Services will live.
kubectl create namespace dev

# Install the official Argo CD bundle (CRDs + controllers + API/UI server).
# We install it *into* the argocd namespace we just created.
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd patch deploy argocd-server \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

kubectl apply -f ../confs/argocd-app.yaml
kubectl apply -f ../confs/argo-ingress.yaml

# Watch Argo CD pods come up (Ctrl+C when all are Running/Ready).
kubectl get pods -n argocd # -w

	# this we don't need since we use ingress now
	#
	# Forward the Argo CD web UI to localhost:8081 (no Ingress needed).
	#
	# 		port-forward:  opens a TCP tunnel via the Kubernetes API from your local machine to a Service/Pod inside the cluster
	# 		svc/argocd-server = target Service in argocd namespace
	# 		8081:80 = bind local port 8081 â†’ Service port 80
	# 		--address 0.0.0.0 lets you open it from your LAN; omit if you prefer localhost-only.
	#
	# sudo kubectl -n argocd port-forward svc/argocd-server 8081:80 --address 0.0.0.0
}


#
# ------------- SERVICE VS INGRESS -------------
#
# Service = Layer-3/4 stable virtual IP inside the cluster that fronts your Pods.
# 
# 	type: ClusterIP (default): internal only. Use port-forward to reach it from your host.
# 	
# 	type: NodePort: opens a high port (30000Ð32767) on each node.
# 	
# 	type: LoadBalancer: asks an external LB to expose it. In k3d, the k3d-proxy container emulates this when you used -p "...@loadbalancer".
# 
# Ingress = Layer-7 HTTP/HTTPS routing (host/path based) to one or more Services.
# 	Requires an Ingress Controller (k3s ships Traefik by default unless disabled).
# 	You use Ingress when you want nice URLs (e.g. http://argocd.local/ or https://app.example.com) and TLS, instead of random ports.
# 
# examples
# 
# No Ingress (dev quick): kubectl port-forward svc/myapp 8080:80 ? open http://localhost:8080
# 
# With LoadBalancer + LB port mapping: create Service type=LoadBalancer, map host ports with -p "...@loadbalancer", then open http://localhost:8080
# 
# With Ingress (nice hostnames/TLS): create an Ingress (or Traefik IngressRoute) that routes Host: myapp.local to svc/myapp:80; expose LB ports 80/443 via -p "80:80@loadbalancer" -p "443:443@loadbalancer"
#
# ----------------------------------------------
# 
# Argo CD bootstraps an admin password in a Secret.
# We extract and decode it for first login.
pass() {
	kubectl -n argocd \
	  get secret argocd-initial-admin-secret \
	  -o jsonpath='{.data.password}' | base64 -d; echo
}


case "$1" in
    pass) pass ;;
    install) install_k3d ;;
    "") setup ;;
    *) echo "Usage: $0 {install|pass|all}" && exit 1 ;;
esac
