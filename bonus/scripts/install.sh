#!/usr/bin/env bash
setup() {
k3d cluster create demo \
  --servers 1 --agents 1 \
  --api-port 6445 \
      -p "8080:80@loadbalancer" \
  --port "8888:8888@loadbalancer"
kubectl create namespace argocd
kubectl create namespace dev

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd patch deploy argocd-server \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

kubectl apply -f ../confs/argocd-app.yaml
kubectl apply -f ../confs/argo-ingress.yaml

helm repo add gitlab https://charts.gitlab.io
helm repo update

#stub to make it work without backups
kubectl -n gitlab create secret generic gitlab-backup-empty \
  --from-literal=config=$'[default]\naccess_key=\nsecret_key=\nuse_https = False\n'

#helm upgrade --install gitlab gitlab/gitlab \
#  --namespace gitlab \
#  -f confs/gitlab-values.yaml

helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.hosts.domain=127.0.0.1.nip.io \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --set global.ingress.class=traefik \
  --timeout 600s

helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.edition=ce \
  --set global.hosts.domain=127.0.0.1.nip.io \
  --set global.hosts.https=false \
  --set global.ingress.class=traefik \
  --set global.ingress.tls.enabled=false \
  --set global.ingress.configureCertmanager=false \
  --set certmanager.install=false \
  --set nginx-ingress.enabled=false \
  --set global.appConfig.enableUsagePing=false \
  --set global.appConfig.enableSeatLink=false \
  --set global.appConfig.object_store.enabled=false \
  --set global.appConfig.artifacts.enabled=false \
  --set global.appConfig.lfs.enabled=false \
  --set global.appConfig.uploads.enabled=false \
  --set global.appConfig.packages.enabled=false \
  --set global.minio.enabled=false \
  --set global.kas.enabled=false \
  --set registry.enabled=false \
  --set gitlab-runner.install=false \
  --set prometheus.install=false \
  --set grafana.enabled=false \
  --set gitlab.webservice.minReplicas=1 \
  --set gitlab.webservice.maxReplicas=1 \
  --set gitlab.sidekiq.minReplicas=1 \
  --set gitlab.sidekiq.maxReplicas=1 \
  --timeout 1200s

}

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
