#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd docker
require_cmd kind
require_cmd kubectl
require_cmd sed

"${SCRIPT_DIR}/gitea-init-config.sh"

info "Starting local registry and Gitea containers"
docker compose -f "${PLATFORM_DIR}/docker-compose.yaml" --env-file "${PLATFORM_DIR}/.env" up -d registry gitea
"${SCRIPT_DIR}/gitea-bootstrap.sh"

GENERATED_KIND_CONFIG="${PLATFORM_DIR}/kind/kind-config.generated.yaml"
cp "${PLATFORM_DIR}/kind/kind-config.yaml.tpl" "${GENERATED_KIND_CONFIG}"
sed -i.bak "s/__KIND_CLUSTER_NAME__/${KIND_CLUSTER_NAME}/g" "${GENERATED_KIND_CONFIG}"
sed -i.bak "s/__LOCAL_REGISTRY_HOST__/${LOCAL_REGISTRY_HOST}/g" "${GENERATED_KIND_CONFIG}"
sed -i.bak "s/__LOCAL_REGISTRY_PORT__/${LOCAL_REGISTRY_PORT}/g" "${GENERATED_KIND_CONFIG}"
sed -i.bak "s/__REGISTRY_CONTAINER_NAME__/${REGISTRY_CONTAINER_NAME}/g" "${GENERATED_KIND_CONFIG}"
sed -i.bak "s/__KIND_INGRESS_HTTP_PORT__/${KIND_INGRESS_HTTP_PORT}/g" "${GENERATED_KIND_CONFIG}"
sed -i.bak "s/__KIND_INGRESS_HTTPS_PORT__/${KIND_INGRESS_HTTPS_PORT}/g" "${GENERATED_KIND_CONFIG}"
rm -f "${GENERATED_KIND_CONFIG}.bak"

if kind_cluster_exists; then
  info "kind cluster '${KIND_CLUSTER_NAME}' already exists; skipping creation"
else
  info "Creating kind cluster '${KIND_CLUSTER_NAME}'"
  kind create cluster --name "${KIND_CLUSTER_NAME}" --config "${GENERATED_KIND_CONFIG}"
fi

ensure_kind_kubectl_context

info "Connecting registry container to kind network (idempotent)"
docker network connect kind "${REGISTRY_CONTAINER_NAME}" >/dev/null 2>&1 || true

info "Publishing local registry metadata inside cluster"
kubectl apply --validate=false -f "${PLATFORM_DIR}/manifests/local-registry-hosting-configmap.yaml"

"${SCRIPT_DIR}/install-ingress.sh"

info "Platform is up"
info "Host Gitea URL: ${GITEA_URL_FROM_CLUSTER}"
