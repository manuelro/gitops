#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
require_cmd curl
ensure_kind_kubectl_context

ARGOCD_BIN="$(resolve_argocd_bin)"

INFRA_REPO_URL="$(gitea_infra_repo_url)"

info "Check: Argo CD pods Running"
kubectl -n "${ARGO_NAMESPACE}" wait --for=condition=Ready pod --all --timeout=300s >/dev/null

if [[ "${ARGO_EXPOSE_METHOD}" == "port-forward" ]]; then
  info "Check: Argo UI/API reachable via port-forward"
  kubectl -n "${ARGO_NAMESPACE}" port-forward svc/argocd-server "${ARGOCD_PORT_FORWARD_PORT}:80" >/tmp/argocd-pf.log 2>&1 &
  PF_PID=$!
  trap 'kill ${PF_PID} >/dev/null 2>&1 || true' EXIT
  sleep 3
  curl -fsS "http://127.0.0.1:${ARGOCD_PORT_FORWARD_PORT}/api/version" >/dev/null
else
  info "Check: Argo UI/API reachable via ingress"
  curl -fsS "http://${ARGO_INGRESS_HOST}/api/version" >/dev/null
fi

if [[ -z "${ARGOCD_ADMIN_PASSWORD:-}" ]]; then
  ARGOCD_ADMIN_PASSWORD="$("${SCRIPT_DIR}/argocd-admin-password.sh")"
fi

ARGO_SERVER="127.0.0.1:${ARGOCD_PORT_FORWARD_PORT}"
if [[ "${ARGO_EXPOSE_METHOD}" == "ingress" ]]; then
  ARGO_SERVER="${ARGO_INGRESS_HOST}"
fi

info "Check: repo registration succeeds without DNS/connection errors"
"${ARGOCD_BIN}" login "${ARGO_SERVER}" \
  --username admin \
  --password "${ARGOCD_ADMIN_PASSWORD}" \
  --grpc-web \
  --insecure >/dev/null

if [[ -n "${ARGO_REPO_USERNAME}" && -n "${ARGO_REPO_PASSWORD}" ]]; then
  "${ARGOCD_BIN}" repo add "${INFRA_REPO_URL}" \
    --username "${ARGO_REPO_USERNAME}" \
    --password "${ARGO_REPO_PASSWORD}" \
    --insecure-skip-server-verification \
    --upsert >/dev/null
else
  "${ARGOCD_BIN}" repo add "${INFRA_REPO_URL}" \
    --insecure-skip-server-verification \
    --upsert >/dev/null
fi

"${ARGOCD_BIN}" repo get "${INFRA_REPO_URL}" >/dev/null

info "Argo acceptance checks passed"
