#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
ensure_kind_kubectl_context

if [[ "${ARGO_EXPOSE_METHOD}" == "port-forward" ]]; then
  info "Starting Argo CD port-forward on 127.0.0.1:${ARGOCD_PORT_FORWARD_PORT}"
  info "UI/API: http://127.0.0.1:${ARGOCD_PORT_FORWARD_PORT}"
  kubectl -n "${ARGO_NAMESPACE}" port-forward svc/argocd-server "${ARGOCD_PORT_FORWARD_PORT}:80"
else
  info "Argo CD ingress endpoint: http://${ARGO_INGRESS_HOST}"
  info "No port-forward needed for ingress mode"
fi
