#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${PLATFORM_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${PLATFORM_DIR}/.env"
fi

: "${KIND_CLUSTER_NAME:=gitops-local}"
: "${WORKSPACE_ROOT:=local-gitops-e2e}"
: "${LOCAL_REGISTRY_HOST:=localhost}"
: "${LOCAL_REGISTRY_PORT:=5001}"
: "${REGISTRY_CONTAINER_NAME:=kind-registry}"
: "${INGRESS_NAMESPACE:=ingress-nginx}"
: "${KIND_INGRESS_HTTP_PORT:=8081}"
: "${KIND_INGRESS_HTTPS_PORT:=8443}"
: "${GITEA_URL_FROM_CLUSTER:=http://host.docker.internal:3000}"
: "${GITEA_URL_FROM_HOST:=http://localhost:3000}"
: "${GITEA_CONTAINER_NAME:=gitops-gitea}"
: "${GITEA_ADMIN_USERNAME:=gitops-admin}"
: "${GITEA_ADMIN_PASSWORD:=admin12345}"
: "${GITEA_ADMIN_EMAIL:=admin@example.local}"
: "${ARGO_NAMESPACE:=argocd}"
: "${ARGO_EXPOSE_METHOD:=port-forward}"
: "${ARGOCD_VERSION:=v2.12.3}"
: "${ARGO_REDIS_IMAGE:=public.ecr.aws/docker/library/redis:7.0.15-alpine}"
: "${ARGO_INGRESS_HOST:=argocd.localtest.me}"
: "${ARGOCD_PORT_FORWARD_PORT:=8080}"
: "${GITEA_REPO_HOST_FROM_CLUSTER:=http://host.docker.internal:3000}"
: "${GITEA_REPO_OWNER:=gitops}"
: "${INFRA_REPO_NAME:=infra}"
: "${APP_REPO_NAME:=app}"
: "${INFRA_BOOTSTRAP_PATH:=bootstrap}"
: "${ARGO_PROJECT:=default}"
: "${ARGO_REPO_USERNAME:=}"
: "${ARGO_REPO_PASSWORD:=}"
: "${ARGOCD_CLI_BIN:=argocd}"
: "${K8S_DASHBOARD_NAMESPACE:=kubernetes-dashboard}"
: "${K8S_DASHBOARD_PORT_FORWARD_PORT:=10443}"
: "${BENCH_BASE_URL:=http://localhost:${KIND_INGRESS_HTTP_PORT}}"
: "${BENCH_SPIKE_USERS:=40000}"
: "${BENCH_SPIKE_RAMP_SECONDS:=120}"
: "${BENCH_SPIKE_HOLD_SECONDS:=600}"
: "${BENCH_RAMP_USERS:=40000}"
: "${BENCH_RAMP_SECONDS:=1800}"
: "${BENCH_HOLD_SECONDS:=1800}"
: "${BENCH_RAMPDOWN_SECONDS:=900}"
: "${BENCH_REFRESH_RATE:=0.10}"
: "${BENCH_SESSION_SECONDS:=300}"

info() {
  printf '[platform] %s\n' "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

kind_cluster_exists() {
  kind get clusters 2>/dev/null | grep -Fxq "${KIND_CLUSTER_NAME}"
}

gitea_infra_repo_url() {
  printf '%s/%s/%s.git' "${GITEA_REPO_HOST_FROM_CLUSTER%/}" "${GITEA_REPO_OWNER}" "${INFRA_REPO_NAME}"
}

ensure_kind_kubectl_context() {
  local expected_context="kind-${KIND_CLUSTER_NAME}"

  require_cmd kubectl
  require_cmd kind

  if ! kind_cluster_exists; then
    echo "kind cluster '${KIND_CLUSTER_NAME}' does not exist" >&2
    exit 1
  fi

  kind export kubeconfig --name "${KIND_CLUSTER_NAME}" >/dev/null

  local current_context=""
  current_context="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "${current_context}" != "${expected_context}" ]]; then
    info "Switching kubectl context to '${expected_context}'"
    kubectl config use-context "${expected_context}" >/dev/null
  fi
}

resolve_argocd_bin() {
  if [[ -x "${ARGOCD_CLI_BIN}" ]]; then
    printf '%s\n' "${ARGOCD_CLI_BIN}"
    return
  fi

  if command -v "${ARGOCD_CLI_BIN}" >/dev/null 2>&1; then
    command -v "${ARGOCD_CLI_BIN}"
    return
  fi

  if [[ "${ARGOCD_CLI_BIN}" != "argocd" ]]; then
    echo "Configured ARGOCD_CLI_BIN not found or not executable: ${ARGOCD_CLI_BIN}" >&2
  fi
  echo "Missing required command: argocd" >&2
  exit 1
}
