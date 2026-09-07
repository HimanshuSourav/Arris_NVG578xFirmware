#!/usr/bin/env bash
# Download and extract the CommScope NVG578 open-source release from SourceForge.
# GitHub rejects the ~760MB tarball (100MB file limit); keep it out of git.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARBALL="${NVG578_TARBALL:-$ROOT/nvg578.9.5.0h4.tar.gz}"
DEST="${NVG578_SRC_DIR:-$ROOT/nvg578.9.5.0h4}"
URL="${NVG578_URL:-https://sourceforge.net/projects/nvg578.arris/files/nvg578.9.5.0h4.tar.gz/download}"
EXPECTED_BYTES="${NVG578_EXPECTED_BYTES:-797288798}"

if [ -x "$DEST/build" ] && [ -f "$DEST/bcm963xx/bcm963xx_5.02L.07p2_consumer_release.tar.gz" ]; then
  echo "Source already present at $DEST"
  exit 0
fi

if [ ! -f "$TARBALL" ] || [ "$(stat -c%s "$TARBALL")" != "$EXPECTED_BYTES" ]; then
  echo "Downloading NVG578 OSS release (~760MB)..."
  wget --progress=dot:giga -O "$TARBALL.partial" "$URL"
  mv -f "$TARBALL.partial" "$TARBALL"
fi

actual=$(stat -c%s "$TARBALL")
if [ "$actual" != "$EXPECTED_BYTES" ]; then
  echo "Unexpected tarball size $actual (expected $EXPECTED_BYTES)" >&2
  exit 1
fi

echo "Extracting to $DEST ..."
tar -xzf "$TARBALL" -C "$ROOT"
test -x "$DEST/build"
echo "Ready: $DEST"
