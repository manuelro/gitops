#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd docker
require_cmd kind

info "Docker services"
docker compose -f "${PLATFORM_DIR}/docker-compose.yaml" --env-file "${PLATFORM_DIR}/.env" ps

echo
info "kind clusters"
kind get clusters || true

echo
if kind_cluster_exists; then
  info "Kubernetes nodes"
  kubectl get nodes -o wide
  echo
  info "Ingress controller"
  kubectl -n "${INGRESS_NAMESPACE}" get pods -o wide || true
  echo
  if kubectl get namespace "${ARGO_NAMESPACE}" >/dev/null 2>&1; then
    info "Argo CD pods"
    kubectl -n "${ARGO_NAMESPACE}" get pods -o wide
  else
    info "Argo CD namespace '${ARGO_NAMESPACE}' is not present"
  fi
else
  info "Cluster '${KIND_CLUSTER_NAME}' is not created"
fi
