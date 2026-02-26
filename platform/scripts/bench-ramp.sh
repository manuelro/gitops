#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

require_cmd k6

"${SCRIPT_DIR}/bench-preflight.sh"

mkdir -p "${PLATFORM_DIR}/.run/k6"
STAMP="$(date +%Y%m%d-%H%M%S)"
SUMMARY_FILE="${PLATFORM_DIR}/.run/k6/ramp-summary-${STAMP}.json"

info "Running k6 ramp-and-hold scenario"
TARGET_URL="${BENCH_BASE_URL}/" \
RAMP_USERS="${BENCH_RAMP_USERS}" \
RAMP_SECONDS="${BENCH_RAMP_SECONDS}" \
HOLD_SECONDS="${BENCH_HOLD_SECONDS}" \
RAMPDOWN_SECONDS="${BENCH_RAMPDOWN_SECONDS}" \
REFRESH_RATE="${BENCH_REFRESH_RATE}" \
SESSION_SECONDS="${BENCH_SESSION_SECONDS}" \
k6 run \
  --summary-export "${SUMMARY_FILE}" \
  "${PLATFORM_DIR}/bench/k6/homepage-ramp-hold.js"

info "k6 summary exported: ${SUMMARY_FILE}"
