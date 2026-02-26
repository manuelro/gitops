#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/install-argocd.sh"
"${SCRIPT_DIR}/argocd-repo-add.sh"
"${SCRIPT_DIR}/argocd-bootstrap.sh"
