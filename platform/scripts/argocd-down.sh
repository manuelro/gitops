#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl

info "Deleting Argo CD namespace (${ARGO_NAMESPACE})"
kubectl delete namespace "${ARGO_NAMESPACE}" --ignore-not-found

info "Removing generated bootstrap manifest"
rm -f "${PLATFORM_DIR}/manifests/bootstrap-app.generated.yaml"
