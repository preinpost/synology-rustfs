#!/bin/sh
# Build the RustFS SPK with the spksrc docker image.
#
# usage: scripts/build.sh [arch ...]      (default: x64 aarch64)
#   arch is a spksrc arch name, the DSM version is fixed to 7.1
#   e.g. scripts/build.sh x64
#
# environment:
#   SPKSRC_IMAGE   docker image (default ghcr.io/synocommunity/spksrc)
#   NO_DOCKER=1    run make directly (inside the spksrc container / CI)
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPKSRC_IMAGE="${SPKSRC_IMAGE:-ghcr.io/synocommunity/spksrc}"
TCVERSION=7.1

[ $# -gt 0 ] || set -- x64 aarch64

"${ROOT}/scripts/sync-overlay.sh"

targets=""
for arch in "$@"; do
   targets="${targets} arch-${arch}-${TCVERSION}"
done

if [ "${NO_DOCKER:-0}" = "1" ]; then
   # shellcheck disable=SC2086
   make -C "${ROOT}/spksrc/spk/rustfs" ${targets}
else
   # The spksrc image and the synology toolchains are x86_64 only.
   # The build runs in a docker volume (case sensitive, native permissions);
   # bind mounting the tree from macOS/Windows breaks the toolchain extraction.
   # The volume keeps downloaded toolchains/distfiles between runs.
   mkdir -p "${ROOT}/dist"
   # shellcheck disable=SC2086
   docker run --rm --platform linux/amd64 \
      -v "${ROOT}:/src:ro" -v "${ROOT}/dist:/dist" \
      -v "${SPKSRC_VOLUME:-synology-rustfs-spksrc}:/spksrc" \
      "${SPKSRC_IMAGE}" sh -euc '
         rsync -a --delete --exclude /.git --exclude /distrib/ --exclude /packages/ \
            --exclude "work/" --exclude "work-*/" /src/spksrc/ /spksrc/
         make -C /spksrc/spk/rustfs '"${targets}"'
         cp /spksrc/packages/rustfs_*.spk /dist/'
   ls -l "${ROOT}"/dist/*.spk
   exit 0
fi

mkdir -p "${ROOT}/dist"
cp "${ROOT}"/spksrc/packages/rustfs_*.spk "${ROOT}/dist/"
ls -l "${ROOT}"/dist/*.spk
