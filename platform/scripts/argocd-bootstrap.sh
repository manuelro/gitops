#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
require_cmd sed
ensure_kind_kubectl_context

INFRA_REPO_URL="$(gitea_infra_repo_url)"
RENDERED_MANIFEST="${PLATFORM_DIR}/manifests/bootstrap-app.generated.yaml"

cp "${PLATFORM_DIR}/manifests/bootstrap-app.yaml.tpl" "${RENDERED_MANIFEST}"
sed -i.bak "s|__ARGO_NAMESPACE__|${ARGO_NAMESPACE}|g" "${RENDERED_MANIFEST}"
sed -i.bak "s|__ARGO_PROJECT__|${ARGO_PROJECT}|g" "${RENDERED_MANIFEST}"
sed -i.bak "s|__INFRA_REPO_URL__|${INFRA_REPO_URL}|g" "${RENDERED_MANIFEST}"
sed -i.bak "s|__INFRA_BOOTSTRAP_PATH__|${INFRA_BOOTSTRAP_PATH}|g" "${RENDERED_MANIFEST}"
rm -f "${RENDERED_MANIFEST}.bak"

info "Applying bootstrap Application from ${RENDERED_MANIFEST}"
kubectl apply -f "${RENDERED_MANIFEST}"

info "Bootstrap application status"
kubectl -n "${ARGO_NAMESPACE}" get application infra-bootstrap
