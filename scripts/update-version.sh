#!/bin/sh
# Update cross/rustfs and spk/rustfs to a new upstream release and regenerate digests.
#
# usage: scripts/update-version.sh <version>     e.g. scripts/update-version.sh 1.0.5
#
# Downloads the musl zips, verifies them against the upstream SHA256SUMS
# and writes cross/rustfs/digests.
set -eu

VERSION="${1:?usage: $0 <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="https://github.com/rustfs/rustfs/releases/download/${VERSION}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }
sha1()   { if command -v sha1sum   >/dev/null; then sha1sum "$1";   else shasum -a 1 "$1";   fi | cut -d' ' -f1; }
md5()    { if command -v md5sum    >/dev/null; then md5sum "$1" | cut -d' ' -f1; else md5 -q "$1"; fi; }

curl -fsSL -o "${TMP}/SHA256SUMS" "${BASE}/SHA256SUMS"

: > "${TMP}/digests"
for arch in x86_64 aarch64; do
   f="rustfs-linux-${arch}-musl-v${VERSION}.zip"
   echo "downloading ${f}"
   curl -fsSL -o "${TMP}/${f}" "${BASE}/${f}"
   s256="$(sha256 "${TMP}/${f}")"
   if ! grep -q "^${s256}[[:space:]]\+\*\?${f}\$" "${TMP}/SHA256SUMS"; then
      echo "SHA256 mismatch with upstream SHA256SUMS for ${f}" >&2
      exit 1
   fi
   {
      echo "${f} SHA1 $(sha1 "${TMP}/${f}")"
      echo "${f} SHA256 ${s256}"
      echo "${f} MD5 $(md5 "${TMP}/${f}")"
   } >> "${TMP}/digests"
done

cp "${TMP}/digests" "${ROOT}/cross/rustfs/digests"
sed -i.bak "s/^PKG_VERS = .*/PKG_VERS = ${VERSION}/" "${ROOT}/cross/rustfs/Makefile"
sed -i.bak -e "s/^SPK_VERS = .*/SPK_VERS = ${VERSION}/" -e "s/^SPK_REV = .*/SPK_REV = 1/" \
   -e "s|^CHANGELOG = .*|CHANGELOG = \"Update RustFS to ${VERSION}.<br/>Changelog: <a target=\\\\\"_blank\\\\\" href=\\\\\"https://github.com/rustfs/rustfs/releases/tag/${VERSION}\\\\\">https://github.com/rustfs/rustfs/releases/tag/${VERSION}</a>\"|" \
   "${ROOT}/spk/rustfs/Makefile"
rm -f "${ROOT}/cross/rustfs/Makefile.bak" "${ROOT}/spk/rustfs/Makefile.bak"
echo "updated to ${VERSION}"
