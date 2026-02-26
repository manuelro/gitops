#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

"${SCRIPT_DIR}/down.sh"

info "Removing persistent data directories"
rm -rf "${PLATFORM_DIR}/data"

info "Removing generated kind config"
rm -f "${PLATFORM_DIR}/kind/kind-config.generated.yaml"

info "Removing generated Argo CD manifests"
rm -f "${PLATFORM_DIR}/manifests/bootstrap-app.generated.yaml"
