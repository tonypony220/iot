#!/usr/bin/env bash
GIT_HOST="gitlab.127.0.0.1.nip.io:8080"      # must match your git remote host
PROJECT="root/iot.git"                        # project path
REMOTE_URL="http://${GIT_HOST}/${PROJECT}"
NAMESPACE="gitlab"
USER="root"

#push()  {
##!/usr/bin/env bash
#
#	# Get GitLab root password from the k8s Secret
#	GITLAB_PASS=$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
#	  -o jsonpath="{.data.password}" | base64 --decode)
#
## Write ~/.netrc for the *current* user (no sudo)
#	cat > "${HOME}/.netrc" <<EOF
#machine ${GIT_HOST}
#login root
#password ${GITLAB_PASS}
#EOF
#	chmod 600 "${HOME}/.netrc"
#
#	# One-time remote setup + push
#	git remote remove origin 2>/dev/null || true
#	git remote add origin "${REMOTE_URL}"
#	git push -u origin HEAD
#}

secret ()  {
	#!/usr/bin/env bash
	set -euo pipefail

	# Tunables (override via env if needed)
	GITLAB_NS="${GITLAB_NS:-gitlab}"
	ARGO_NS="${ARGO_NS:-argocd}"
	SECRET_NAME="${SECRET_NAME:-repo-gitlab-iot-http}"
	REPO_URL="${REPO_URL:-http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot.git}"
	USERNAME="${USERNAME:-root}"   # or set to your deploy token username

	# Get GitLab root password from the installed chart's secret
	PASS="$(kubectl -n "${GITLAB_NS}" get secret gitlab-gitlab-initial-root-password \
	  -o jsonpath='{.data.password}' | base64 -d)"

	cat > /tmp/${SECRET_NAME}.yaml <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${ARGO_NS}
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  url: ${REPO_URL}
  username: ${USERNAME}
  password: ${PASS}
YAML

	kubectl apply -f /tmp/${SECRET_NAME}.yaml

	# Build + apply the Argo CD repository Secret (HTTP basic auth)
	#kubectl -n "${ARGO_NS}" create secret generic "${SECRET_NAME}" \
	#  --type=Opaque \
	#  --from-literal=url="${REPO_URL}" \
	#  --from-literal=username="${USERNAME}" \
	#  --from-literal=password="${PASS}" \
	#  --labels="argocd.argoproj.io/secret-type=repository" \
	#  --dry-run=client -o yaml | kubectl apply -f -

	echo "? Argo CD repo secret '${SECRET_NAME}' applied in namespace '${ARGO_NS}'."
}

push()  {
	# Grab the initial root password from the Secret
	PASS="$(kubectl -n "${NAMESPACE}" get secret gitlab-gitlab-initial-root-password \
	  -o jsonpath='{.data.password}' | base64 -d)"

	# Tell Git (for *root*) to use the on-disk credential store
	git config --global credential.helper store

	# Save the credential for this host into /root/.git-credentials
	# (Git will read this automatically for HTTP(S))
	printf "http://%s:%s@%s\n" "$USER" "$PASS" "$GIT_HOST" > /root/.git-credentials
	chmod 600 /root/.git-credentials

	# Ensure Git never tries to prompt in scripts
	export GIT_TERMINAL_PROMPT=0

	# Set remote and push
	git remote remove origin 2>/dev/null || true
	git remote add origin "${REMOTE_URL}"
	git push -u origin HEAD
}

wait()  {
	echo "==> Waiting for the initial root password Secret..."
	# Wait for the Secret to exist and contain a password
	until kubectl -n "${NAMESPACE}" get secret gitlab-gitlab-initial-root-password >/dev/null 2>&1; do
	  sleep 3
	done
	until kubectl -n "${NAMESPACE}" get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' >/dev/null 2>&1; do
	  sleep 3
	done

	echo "==> Waiting for GitLab web to become Ready (readiness endpoint)..."
	# Readiness endpoint: returns 200 only when all critical components are ready (web, db, migrations, etc.)
	# We retry for up to ~15 minutes (90 * 10s)
	RETRIES=90
	until curl -fsS "${GIT_HOST}/-/readiness?all=1" >/dev/null 2>&1; do
	  (( RETRIES-- )) || { echo "GitLab did not become ready in time"; exit 1; }
	  sleep 10
	done

	echo "==> Confirming basic health..."
	curl -fsS "${GIT_HOST}/-/health" >/dev/null
}

setup() {

	set -euo pipefail
	k3d cluster create demo \
	  --servers 1 --agents 2 \
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
	kubectl create namespace gitlab

	#stub to make it work without backups
	kubectl -n gitlab create secret generic gitlab-backup-empty \
	  --from-literal=config=$'[default]\naccess_key=\nsecret_key=\nuse_https = False\n'

	helm upgrade --install gitlab gitlab/gitlab \
	  --namespace gitlab \
	  -f ../confs/gitlab-values.yaml

	wait
	secret
	push
	# add wait ready 
	#
	#pass 
	#kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d; echo


	#helm upgrade --install gitlab gitlab/gitlab \
	#  -n gitlab \
	#  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
	#  --set global.hosts.domain=127.0.0.1.nip.io \
	#  --set global.hosts.externalIP=0.0.0.0 \
	#  --set global.hosts.https=false \
	#  --set global.ingress.class=traefik \
	#  --timeout 600s
	#
	#helm upgrade --install gitlab gitlab/gitlab \
	#  -n gitlab \
	#  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
	#  --set global.edition=ce \
	#  --set global.hosts.domain=127.0.0.1.nip.io \
	#  --set global.hosts.https=false \
	#  --set global.ingress.class=traefik \
	#  --set global.ingress.tls.enabled=false \
	#  --set global.ingress.configureCertmanager=false \
	#  --set certmanager.install=false \
	#  --set nginx-ingress.enabled=false \
	#  --set global.appConfig.enableUsagePing=false \
	#  --set global.appConfig.enableSeatLink=false \
	#  --set global.appConfig.object_store.enabled=false \
	#  --set global.appConfig.artifacts.enabled=false \
	#  --set global.appConfig.lfs.enabled=false \
	#  --set global.appConfig.uploads.enabled=false \
	#  --set global.appConfig.packages.enabled=false \
	#  --set global.minio.enabled=false \
	#  --set global.kas.enabled=false \
	#  --set registry.enabled=false \
	#  --set gitlab-runner.install=false \
	#  --set prometheus.install=false \
	#  --set grafana.enabled=false \
	#  --set gitlab.webservice.minReplicas=1 \
	#  --set gitlab.webservice.maxReplicas=1 \
	#  --set gitlab.sidekiq.minReplicas=1 \
	#  --set gitlab.sidekiq.maxReplicas=1 \
	#  --timeout 1200s

}

case "$1" in
    push) push ;;
    secret) secret ;;
    install) install_k3d ;;
    "") setup ;;
    *) echo "Usage: $0 {install|pass|all}" && exit 1 ;;
esac
