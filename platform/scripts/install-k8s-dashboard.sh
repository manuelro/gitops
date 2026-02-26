#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
ensure_kind_kubectl_context

DASHBOARD_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"

info "Installing Kubernetes Dashboard from ${DASHBOARD_MANIFEST_URL}"
kubectl apply --validate=false -f "${DASHBOARD_MANIFEST_URL}"

info "Creating admin ServiceAccount and ClusterRoleBinding"
kubectl apply --validate=false -f - <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: ${K8S_DASHBOARD_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: admin-user
    namespace: ${K8S_DASHBOARD_NAMESPACE}
YAML

info "Waiting for dashboard deployment"
kubectl -n "${K8S_DASHBOARD_NAMESPACE}" rollout status deployment/kubernetes-dashboard --timeout=180s

info "Kubernetes Dashboard installed"
