#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

CONFIG_DIR="${PLATFORM_DIR}/data/gitea/gitea/conf"
CONFIG_FILE="${CONFIG_DIR}/app.ini"

mkdir -p "${CONFIG_DIR}"

cat > "${CONFIG_FILE}" <<EOC
APP_NAME = Local GitOps Gitea
RUN_MODE = prod
RUN_USER = git
WORK_PATH = /data/gitea

[server]
APP_DATA_PATH = /data/gitea
DOMAIN = localhost
SSH_DOMAIN = localhost
HTTP_PORT = 3000
ROOT_URL = ${GITEA_URL_FROM_HOST}
DISABLE_SSH = false
SSH_PORT = ${GITEA_SSH_PORT}
START_SSH_SERVER = true
OFFLINE_MODE = false

[database]
DB_TYPE = sqlite3
PATH = /data/gitea/gitea.db

[security]
INSTALL_LOCK = true
SECRET_KEY = local-gitops-secret-key
INTERNAL_TOKEN = local-gitops-internal-token
PASSWORD_HASH_ALGO = pbkdf2

[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = false
ENABLE_NOTIFY_MAIL = false

[repository]
ROOT = /data/git/repositories
DEFAULT_BRANCH = main

[openid]
ENABLE_OPENID_SIGNIN = false
ENABLE_OPENID_SIGNUP = false

[session]
PROVIDER = file

[picture]
DISABLE_GRAVATAR = true
ENABLE_FEDERATED_AVATAR = false

[log]
MODE = console
LEVEL = info
ROOT_PATH = /data/gitea/log
EOC

info "Generated Gitea config at ${CONFIG_FILE}"
