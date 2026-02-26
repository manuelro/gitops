#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
ensure_kind_kubectl_context

INGRESS_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml"

info "Installing ingress-nginx from ${INGRESS_MANIFEST_URL}"
kubectl apply --validate=false -f "${INGRESS_MANIFEST_URL}"

info "Labeling control-plane node for ingress scheduling"
kubectl label node "${KIND_CLUSTER_NAME}-control-plane" ingress-ready=true --overwrite

info "Waiting for ingress-nginx controller rollout"
kubectl -n "${INGRESS_NAMESPACE}" rollout status deployment/ingress-nginx-controller --timeout=180s
