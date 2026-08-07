#!/usr/bin/env bash
# Sanity-check a built `gs` binary by rendering a test EPS to PNG.
#
# Usage:
#   ./build/verify.sh <path-to-gs-binary>

set -euo pipefail

GS_BIN="${1:?Usage: verify.sh <path-to-gs-binary>}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_EPS="${ROOT_DIR}/build/testdata/smoke-test.eps"

if [[ ! -x "${GS_BIN}" ]]; then
  echo "Not an executable file: ${GS_BIN}" >&2
  exit 1
fi

OUT_DIR="$(mktemp -d)"
trap 'rm -rf "${OUT_DIR}"' EXIT
OUT_PNG="${OUT_DIR}/smoke-test.png"

echo "Rendering ${TEST_EPS} with ${GS_BIN}..."
"${GS_BIN}" \
  -dNOPAUSE -dBATCH -dSAFER \
  -sDEVICE=pngalpha -dEPSCrop -r150 \
  -sOutputFile="${OUT_PNG}" \
  "${TEST_EPS}"

if [[ ! -s "${OUT_PNG}" ]]; then
  echo "FAIL: output PNG missing or empty: ${OUT_PNG}" >&2
  exit 1
fi

SIZE="$(wc -c < "${OUT_PNG}" | tr -d ' ')"
echo "OK: rendered ${OUT_PNG} (${SIZE} bytes)"
