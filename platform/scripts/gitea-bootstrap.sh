#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd docker
require_cmd curl

if ! docker ps --format '{{.Names}}' | grep -Fxq "${GITEA_CONTAINER_NAME}"; then
  echo "Gitea container '${GITEA_CONTAINER_NAME}' is not running" >&2
  exit 1
fi

GITEA_CONFIG_PATH="/data/gitea/conf/app.ini"

info "Waiting for Gitea HTTP endpoint (${GITEA_URL_FROM_HOST})"
for _ in {1..60}; do
  if curl -fsS "${GITEA_URL_FROM_HOST}/api/healthz" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -fsS "${GITEA_URL_FROM_HOST}/api/healthz" >/dev/null 2>&1; then
  echo "Gitea did not become ready in time" >&2
  exit 1
fi

info "Ensuring admin user '${GITEA_ADMIN_USERNAME}' exists"
if ! docker exec --user git "${GITEA_CONTAINER_NAME}" gitea --config "${GITEA_CONFIG_PATH}" admin user list | awk '{print $2}' | grep -Fxq "${GITEA_ADMIN_USERNAME}"; then
  docker exec --user git "${GITEA_CONTAINER_NAME}" gitea admin user create \
    --config "${GITEA_CONFIG_PATH}" \
    --username "${GITEA_ADMIN_USERNAME}" \
    --password "${GITEA_ADMIN_PASSWORD}" \
    --email "${GITEA_ADMIN_EMAIL}" \
    --admin \
    --must-change-password=false
else
  info "Admin user already exists"
fi

api_post() {
  local path="$1"
  local data="$2"
  curl -sS -o /dev/null -w '%{http_code}' \
    -u "${GITEA_ADMIN_USERNAME}:${GITEA_ADMIN_PASSWORD}" \
    -H 'Content-Type: application/json' \
    -X POST "${GITEA_URL_FROM_HOST}${path}" \
    -d "${data}"
}

info "Ensuring Gitea org '${GITEA_REPO_OWNER}' exists"
org_status="$(api_post '/api/v1/orgs' "{\"username\":\"${GITEA_REPO_OWNER}\",\"visibility\":\"public\"}")"
if [[ "${org_status}" != "201" && "${org_status}" != "422" ]]; then
  echo "Failed to ensure org '${GITEA_REPO_OWNER}' (HTTP ${org_status})" >&2
  exit 1
fi

create_repo() {
  local repo_name="$1"
  local status
  status="$(api_post "/api/v1/orgs/${GITEA_REPO_OWNER}/repos" "{\"name\":\"${repo_name}\",\"private\":false,\"auto_init\":false}")"
  if [[ "${status}" != "201" && "${status}" != "409" && "${status}" != "422" ]]; then
    echo "Failed to ensure repo '${repo_name}' (HTTP ${status})" >&2
    exit 1
  fi
}

info "Ensuring infra/app repos exist"
create_repo "${INFRA_REPO_NAME}"
create_repo "${APP_REPO_NAME}"

info "Gitea bootstrap complete"
info "Repos: ${GITEA_URL_FROM_HOST%/}/${GITEA_REPO_OWNER}/${INFRA_REPO_NAME} and ${GITEA_URL_FROM_HOST%/}/${GITEA_REPO_OWNER}/${APP_REPO_NAME}"
