# ghostscript-macos-builds

Public, AGPL-3.0-compliant redistributor of a minimal, self-contained
**Ghostscript** (`gs`) build for **macOS (arm64 + x64, universal)** —
useful to any app or script that needs a local `gs` binary on macOS
without going through Homebrew. Free to use by anyone, subject to the
AGPL-3.0 terms in [`LICENSE`](LICENSE).

This repo was originally created so that Mi-Farm could render
EPS → raster (JPEG/PNG) locally without bundling `gs` (AGPL-3.0) inside
the Mi-Farm app itself — Mi-Farm calls the binary released here as an
**arm's-length subprocess** at runtime; it does not link against or ship
Ghostscript. That original design rationale is kept as background in
[`docs/PLAN-ghostscript-distro-repo.md`](docs/PLAN-ghostscript-distro-repo.md)
(in Indonesian), but the repo and its releases are general-purpose and
not Mi-Farm-specific.

## Why keep this separate from the app that consumes it

Ghostscript is licensed under **AGPL-3.0**. Bundling it inside a
proprietary app would trigger AGPL obligations for that app. Instead:

- **This repo** builds and redistributes `gs` binaries and carries the
  AGPL §6 obligations (license text, corresponding source, build
  scripts, notices).
- **Consuming apps** (e.g. Mi-Farm, the original motivating use case)
  download a pinned, SHA256-verified binary from this repo's GitHub
  Releases at runtime and spawn it as a subprocess (*mere
  aggregation*) — they can stay proprietary.

## AGPL-3.0 compliance notice

- **License**: [`LICENSE`](LICENSE) — GNU Affero General Public
  License v3.0, copyright Artifex Software, Inc. and the Ghostscript
  contributors.
- **Corresponding source**: each release pins an exact upstream
  Ghostscript/GhostPDL version. The upstream source tarball for that
  version is mirrored under [`source/`](source/) (or linked + archived)
  and referenced in the release notes.
- **Build scripts**: [`build/build-macos.sh`](build/build-macos.sh) and
  the CI workflow in [`.github/workflows/release.yml`](.github/workflows/release.yml)
  are themselves part of the corresponding source — they make every
  released binary reproducible from upstream source.
- **No network use of gs**: `gs` runs strictly as a local CLI process;
  AGPL §13 (network interaction clause) does not apply.
- Every release is tagged with the exact `gs` version it was built
  from; see that release's notes for the source reference and any
  patches applied (normally none).

## What gets built

A single, self-contained `gs` executable per architecture, with no
external `Resource/` directory required at runtime:

- Built with `COMPILE_INITS=1` (default) — PostScript init files and
  resources are baked into the binary.
- Minimal device set: `jpeg` + `pngalpha` (EPS → JPEG/PNG).
- Configured with `--without-x --disable-cups --disable-gtk
  --disable-fontconfig --disable-dbus --without-tesseract` — no X11,
  CUPS, GTK, system font discovery, dbus, or OCR.
- Statically uses the bundled libjpeg/libpng/zlib/freetype from the gs
  source tree — minimal external dependencies (the only linked
  libraries are macOS system ones: `libSystem` + `libiconv`).
- **Minimum macOS version**: `arm64` slice targets **macOS 11.0**
  (Big Sur — the first release with Apple Silicon support); `x64`
  slice targets **macOS 10.15** (Catalina). Set explicitly via
  `MACOSX_DEPLOYMENT_TARGET` in `build/build-macos.sh` — without it,
  clang bakes in whatever SDK version happens to be on the build
  machine, which silently makes the binary unusable on older macOS.
- Expected size: roughly 15–30 MB per architecture.

## Repo layout

```
ghostscript-macos-builds/
├── README.md              # this file
├── LICENSE                # AGPL-3.0
├── build/
│   ├── build-macos.sh     # parametric build recipe (version + arch)
│   └── verify.sh          # renders a test EPS, checks exit 0 + non-empty output
├── source/                 # optional mirror of upstream source tarballs (corresponding source)
├── manifest.json           # machine-readable pointer to the latest release (consumed by downstream apps)
├── docs/
│   └── PLAN-ghostscript-distro-repo.md   # original design doc (Indonesian)
└── .github/workflows/
    └── release.yml         # build arm64+x64 → lipo → checksum → GitHub Release
```

## Building locally

```bash
GS_VERSION=10.04.0 ARCH=arm64 ./build/build-macos.sh
./build/verify.sh ./dist/gs-arm64
```

Build each architecture on a native runner (arm64 on `macos-14`, x64 on
`macos-13` — cross-compiling `gs` is not supported), then combine into
a universal binary:

```bash
lipo -create dist/gs-arm64 dist/gs-x64 -output dist/gs-darwin-universal
```

## Releases

Each GitHub Release contains:

- `gs-darwin-universal` (arm64 + x64 combined via `lipo`)
- `SHA256SUMS`
- `LICENSE`
- Release notes with the exact upstream `gs` version and source
  reference

`manifest.json` at the repo root always points at the latest release
for programmatic discovery (see file for schema). Consumers that need
strong integrity guarantees should still pin an explicit version +
SHA256 in their own codebase rather than trusting the mutable manifest
alone.

## Consuming this repo (integration contract)

1. Prefer a `gs` already installed on the user's system, if present.
2. Otherwise, download the pinned-version binary from this repo's
   releases, **verify its SHA256 against a hash pinned in the
   consuming app** (not just the manifest), then cache it under the
   app's user-data directory.
3. `chmod +x` and strip the `com.apple.quarantine` extended attribute
   before executing (macOS Gatekeeper).
4. If download/verification fails or the machine is offline, fail
   gracefully — do not silently skip verification.

Full sequence diagram and rationale: [`docs/PLAN-ghostscript-distro-repo.md`](docs/PLAN-ghostscript-distro-repo.md), §8–9.

## Versioning & maintenance

One `gs` version is pinned at a time; it is bumped only for security
fixes or when a new device/feature is needed. EPS → raster rendering
is stable, so releases here are expected to be infrequent (a few times
a year or less).
