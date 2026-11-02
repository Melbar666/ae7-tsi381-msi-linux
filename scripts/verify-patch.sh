#!/usr/bin/env bash
# Read-only exact-source verification. Never modifies a live driver.
set -Eeuo pipefail
if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 /path/to/unmodified/linux-source-7.3.0" >&2
  exit 2
fi
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tree="${1%/}"
file="$tree/sound/hda/controllers/intel.c"
[[ -f "$file" ]] || { echo "Missing kernel source" >&2; exit 1; }
stock=ebc82a65f64864a88527e23604e0f3685e8bd646871698b5d78277655e2733f9
patched=7ce243c4c80d855f3523fa526a146ff6a280f81cd03f9ef9afcde9222c23aa8e
[[ "$(sha256sum "$file" | cut -d' ' -f1)" == "$stock" ]] || { echo "Unverified base source SHA" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/sound/hda/controllers"
cp -- "$file" "$tmp/sound/hda/controllers/intel.c"
patch --batch -p1 -d "$tmp" -i "$root/patches/experimental-v77-from-ubuntu-7.3.0-10.patch"
[[ "$(sha256sum "$tmp/sound/hda/controllers/intel.c" | cut -d' ' -f1)" == "$patched" ]] || { echo "Result not exact V77 source" >&2; exit 1; }
echo "PASS exact V77 source reproduction. No live driver changed."
