#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl
ensure_kind_kubectl_context

ARGO_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

info "Installing Argo CD (${ARGOCD_VERSION}) into namespace '${ARGO_NAMESPACE}'"
kubectl create namespace "${ARGO_NAMESPACE}" --dry-run=client -o yaml | kubectl apply --validate=false -f -
kubectl apply --validate=false -n "${ARGO_NAMESPACE}" -f "${ARGO_INSTALL_URL}"

info "Setting Argo CD Redis image to ${ARGO_REDIS_IMAGE}"
kubectl -n "${ARGO_NAMESPACE}" set image deployment/argocd-redis redis="${ARGO_REDIS_IMAGE}" >/dev/null

if [[ "${ARGO_EXPOSE_METHOD}" == "ingress" ]]; then
  info "Configuring Argo CD server for ingress/http mode"
  kubectl -n "${ARGO_NAMESPACE}" patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
  kubectl -n "${ARGO_NAMESPACE}" rollout restart deployment/argocd-server
  kubectl -n "${ARGO_NAMESPACE}" rollout status deployment/argocd-server --timeout=180s

  info "Applying ingress for Argo CD UI (${ARGO_INGRESS_HOST})"
  sed "s/argocd.localtest.me/${ARGO_INGRESS_HOST}/g" \
    "${PLATFORM_DIR}/manifests/argocd-server-ingress.yaml" | kubectl apply --validate=false -f -
fi

info "Waiting for Argo CD core deployments"
kubectl -n "${ARGO_NAMESPACE}" rollout status deployment/argocd-server --timeout=300s
kubectl -n "${ARGO_NAMESPACE}" rollout status deployment/argocd-repo-server --timeout=300s
kubectl -n "${ARGO_NAMESPACE}" rollout status statefulset/argocd-application-controller --timeout=300s

info "Argo CD installation complete"
