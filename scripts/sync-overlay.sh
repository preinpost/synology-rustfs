#!/bin/sh
# Copy our package definitions (cross/rustfs, spk/rustfs) into the spksrc submodule.
# The copies are ignored inside the submodule via .git/info/exclude.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPKSRC="${ROOT}/spksrc"

if [ ! -f "${SPKSRC}/mk/spksrc.spk.mk" ]; then
   echo "spksrc submodule missing: run 'git submodule update --init --depth 1'" >&2
   exit 1
fi

for pkg in cross/rustfs cross/rustfs-license spk/rustfs; do
   rm -rf "${SPKSRC:?}/${pkg}"
   mkdir -p "${SPKSRC}/${pkg}"
   cp -R "${ROOT}/${pkg}/." "${SPKSRC}/${pkg}/"
done

exclude="$(git -C "${SPKSRC}" rev-parse --git-path info/exclude 2>/dev/null || true)"
if [ -n "${exclude}" ]; then
   case "${exclude}" in /*) ;; *) exclude="${SPKSRC}/${exclude}" ;; esac
   mkdir -p "$(dirname "${exclude}")"
   for p in /cross/rustfs/ /cross/rustfs-license/ /spk/rustfs/; do
      grep -qxF "${p}" "${exclude}" 2>/dev/null || echo "${p}" >> "${exclude}"
   done
fi
echo "overlay synced into ${SPKSRC}"
