#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
ensure_kind_kubectl_context

info "Starting Kubernetes Dashboard port-forward"
info "Open: https://127.0.0.1:${K8S_DASHBOARD_PORT_FORWARD_PORT}"
kubectl -n "${K8S_DASHBOARD_NAMESPACE}" port-forward svc/kubernetes-dashboard "${K8S_DASHBOARD_PORT_FORWARD_PORT}:443"
