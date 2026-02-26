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
SUMMARY_FILE="${PLATFORM_DIR}/.run/k6/spike-summary-${STAMP}.json"

info "Running k6 spike scenario"
TARGET_URL="${BENCH_BASE_URL}/" \
SPIKE_USERS="${BENCH_SPIKE_USERS}" \
SPIKE_RAMP_SECONDS="${BENCH_SPIKE_RAMP_SECONDS}" \
SPIKE_HOLD_SECONDS="${BENCH_SPIKE_HOLD_SECONDS}" \
REFRESH_RATE="${BENCH_REFRESH_RATE}" \
SESSION_SECONDS="${BENCH_SESSION_SECONDS}" \
k6 run \
  --summary-export "${SUMMARY_FILE}" \
  "${PLATFORM_DIR}/bench/k6/homepage-spike.js"

info "k6 summary exported: ${SUMMARY_FILE}"
