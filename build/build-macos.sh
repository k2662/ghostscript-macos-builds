#!/usr/bin/env bash
# Build a minimal, self-contained Ghostscript binary for macOS arm64
# (Apple Silicon only — see README for why x64 isn't built here).
#
# Usage:
#   GS_VERSION=10.07.1 ./build/build-macos.sh
#
# Produces: dist/gs-arm64
#
# Must run on an arm64 runner (see .github/workflows/release.yml for
# the current GA runner label — GitHub periodically deprecates old
# macos-NN images, so check https://github.com/actions/runner-images
# if this drifts).

set -euo pipefail

GS_VERSION="${GS_VERSION:?Set GS_VERSION, e.g. GS_VERSION=10.07.1}"
GS_TAG="gs$(echo "${GS_VERSION}" | tr -d '.')"

# Without this, clang bakes in whatever SDK version the build machine
# happens to have (LC_BUILD_VERSION minos) — e.g. a binary built on a
# macOS 26 runner would refuse to run on anything older than macOS 26.
# 11.0 = Big Sur, the first macOS release with Apple Silicon support.
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-11.0}"
echo "MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
SOURCE_DIR="${ROOT_DIR}/source"
mkdir -p "${DIST_DIR}" "${SOURCE_DIR}"

TARBALL="ghostpdl-${GS_VERSION}.tar.gz"
TARBALL_PATH="${SOURCE_DIR}/${TARBALL}"

if [[ ! -f "${TARBALL_PATH}" ]]; then
  echo "Fetching ${TARBALL} (${GS_TAG})..."
  curl -fL -o "${TARBALL_PATH}" \
    "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/${GS_TAG}/${TARBALL}"
else
  echo "Using cached source tarball: ${TARBALL_PATH}"
fi

tar xf "${TARBALL_PATH}" -C "${WORKDIR}"
SRC_DIR="${WORKDIR}/ghostpdl-${GS_VERSION}"

pushd "${SRC_DIR}" >/dev/null

echo "Configuring (minimal, self-contained via COMPILE_INITS)..."
./configure \
  --without-x \
  --disable-cups \
  --disable-gtk \
  --disable-fontconfig \
  --disable-dbus \
  --without-tesseract

echo "Building..."
make -j"$(sysctl -n hw.ncpu)"

popd >/dev/null

OUT_PATH="${DIST_DIR}/gs-arm64"
cp "${SRC_DIR}/bin/gs" "${OUT_PATH}"
chmod +x "${OUT_PATH}"

echo "Built: ${OUT_PATH}"
file "${OUT_PATH}"
