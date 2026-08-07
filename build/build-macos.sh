#!/usr/bin/env bash
# Build a minimal, self-contained Ghostscript binary for macOS.
#
# Usage:
#   GS_VERSION=10.04.0 ARCH=arm64 ./build/build-macos.sh
#
# Produces: dist/gs-<ARCH>
#
# Must run on a native runner for the target arch (macos-14 = arm64,
# macos-13 = x64) — cross-compiling Ghostscript is not supported.

set -euo pipefail

GS_VERSION="${GS_VERSION:?Set GS_VERSION, e.g. GS_VERSION=10.04.0}"
ARCH="${ARCH:?Set ARCH to arm64 or x64}"
GS_TAG="gs$(echo "${GS_VERSION}" | tr -d '.')"

case "${ARCH}" in
  arm64|x64) ;;
  *) echo "ARCH must be arm64 or x64, got: ${ARCH}" >&2; exit 1 ;;
esac

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

echo "Building for ${ARCH}..."
make -j"$(sysctl -n hw.ncpu)"

popd >/dev/null

OUT_PATH="${DIST_DIR}/gs-${ARCH}"
cp "${SRC_DIR}/bin/gs" "${OUT_PATH}"
chmod +x "${OUT_PATH}"

echo "Built: ${OUT_PATH}"
file "${OUT_PATH}"
