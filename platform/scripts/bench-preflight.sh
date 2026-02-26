#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
require_cmd curl
ensure_kind_kubectl_context

if ! command -v k6 >/dev/null 2>&1; then
  echo "Missing required command: k6" >&2
  echo "Install with: brew install k6" >&2
  exit 1
fi

info "Checking homepage endpoint: ${BENCH_BASE_URL}/"
curl -fsS --max-time 10 "${BENCH_BASE_URL}/" >/dev/null

info "Cluster ready summary"
kubectl get nodes
kubectl -n ingress-nginx get pods
kubectl -n demo get pods

info "Benchmark preflight passed"
