#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd docker
require_cmd kind

if kind_cluster_exists; then
  info "Deleting kind cluster '${KIND_CLUSTER_NAME}'"
  kind delete cluster --name "${KIND_CLUSTER_NAME}"
else
  info "kind cluster '${KIND_CLUSTER_NAME}' does not exist"
fi

info "Stopping registry and Gitea containers"
docker compose -f "${PLATFORM_DIR}/docker-compose.yaml" --env-file "${PLATFORM_DIR}/.env" down
