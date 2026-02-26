#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
ensure_kind_kubectl_context

DASHBOARD_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"

info "Removing Kubernetes Dashboard"
kubectl delete -f "${DASHBOARD_MANIFEST_URL}" --ignore-not-found
kubectl delete clusterrolebinding admin-user --ignore-not-found
kubectl -n "${K8S_DASHBOARD_NAMESPACE}" delete serviceaccount admin-user --ignore-not-found
