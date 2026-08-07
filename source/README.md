# source/

Local cache for upstream GhostPDL/Ghostscript source tarballs, used by
[`build/build-macos.sh`](../build/build-macos.sh).

Tarballs downloaded here are **not committed to git** (see
`.gitignore`) — committing large binary tarballs into git history is
avoided on purpose. Instead, the release workflow
([`.github/workflows/release.yml`](../.github/workflows/release.yml))
attaches the exact source tarball used for each build as a **GitHub
Release asset**, which is what satisfies the AGPL-3.0 §6
"corresponding source" requirement (see
[`docs/PLAN-ghostscript-distro-repo.md`](../docs/PLAN-ghostscript-distro-repo.md), §3).
