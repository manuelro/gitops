#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd docker
require_cmd kubectl
require_cmd curl

REGISTRY_ADDR="${LOCAL_REGISTRY_HOST}:${LOCAL_REGISTRY_PORT}"
# Docker daemon on macOS is more reliable with 127.0.0.1 than localhost here.
SMOKE_IMAGE="127.0.0.1:${LOCAL_REGISTRY_PORT}/platform-smoke:latest"

info "Check: registry endpoint"
curl -fsS "http://${REGISTRY_ADDR}/v2/" >/dev/null

info "Check: registry push/pull"
docker pull alpine:3.20 >/dev/null
docker tag alpine:3.20 "${SMOKE_IMAGE}"
docker push "${SMOKE_IMAGE}" >/dev/null
docker pull "${SMOKE_IMAGE}" >/dev/null

info "Check: kind nodes Ready"
kubectl wait --for=condition=Ready nodes --all --timeout=180s >/dev/null

info "Check: ingress controller Running"
kubectl -n "${INGRESS_NAMESPACE}" rollout status deployment/ingress-nginx-controller --timeout=180s >/dev/null

info "Check: pod -> Gitea URL (${GITEA_URL_FROM_CLUSTER})"
kubectl delete pod gitea-reachability-check --ignore-not-found >/dev/null
kubectl run gitea-reachability-check \
  --image=curlimages/curl:8.10.1 \
  --restart=Never \
  --command -- sh -c "curl -fsS --max-time 15 '${GITEA_URL_FROM_CLUSTER}' >/dev/null"
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/gitea-reachability-check --timeout=90s >/dev/null
kubectl delete pod gitea-reachability-check >/dev/null

info "All acceptance checks passed"
