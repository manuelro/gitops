#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
ensure_kind_kubectl_context

INFRA_REPO_URL="$(gitea_infra_repo_url)"

apply_repo_secret() {
  local payload="$1"
  local attempts=0
  until kubectl -n "${ARGO_NAMESPACE}" apply --validate=false -f - <<<"${payload}"; do
    attempts=$((attempts + 1))
    if [[ ${attempts} -ge 5 ]]; then
      return 1
    fi
    sleep 2
  done
}

info "Registering infra repository via Argo repository secret (${INFRA_REPO_URL})"
if [[ -n "${ARGO_REPO_USERNAME}" && -n "${ARGO_REPO_PASSWORD}" ]]; then
  apply_repo_secret "$(cat <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: repo-infra-http
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${INFRA_REPO_URL}
  username: ${ARGO_REPO_USERNAME}
  password: ${ARGO_REPO_PASSWORD}
YAML
)"
else
  apply_repo_secret "$(cat <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: repo-infra-http
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${INFRA_REPO_URL}
YAML
)"
fi

info "Repository registration complete"
