#!/usr/bin/env bash
# Run the vendor firmware build with Perl 5.22.1 and host-tool compiler flags.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${NVG578_SRC_DIR:-$ROOT/nvg578.9.5.0h4}"
PROFILE="${1:-NVG578LX_AX}"

if [ ! -x "$SRC/build" ]; then
  echo "Source tree missing. Run scripts/fetch-source.sh first." >&2
  exit 1
fi

export PERLBREW_ROOT="${PERLBREW_ROOT:-$HOME/perl5/perlbrew}"
# shellcheck disable=SC1091
source "$PERLBREW_ROOT/etc/bashrc"
perlbrew switch perl-5.22.1
export PATH="$PERLBREW_ROOT/perls/perl-5.22.1/bin:$PATH"

# Autoconf packages inherit Broadcom CFLAGS including -Werror=uninitialized,
# which makes the ANSI `const` probe fail and then `#define const` in config.h.
export ac_cv_c_const=yes

cd "$SRC"

# Vendor ./build wipes axis/broadcom and re-extracts. Patch hostTools after extract
# by wrapping the final make: run extract/patch ourselves, then make.
export AXIS_ROOT="$SRC/axis"
export BOARD_MFG="ARRIS"
export PROFILE
export BOARD=NVG578
export MOTOPIA_ARCH=arm
export BOARD_FAMILY=NVG578

if [[ "$PROFILE" != "NVG578LX_AX" ]]; then
  echo "Unknown PROFILE $PROFILE" >&2
  exit 1
fi

BUILD_OUTPUT="$AXIS_ROOT/broadcom"
if [ ! -f "$BUILD_OUTPUT/Makefile" ]; then
  rm -rf "$BUILD_OUTPUT"
  cd "$SRC/bcm963xx"
  tar -xzf "$SRC/bcm963xx/bcm963xx_5.02L.07p2_consumer_release.tar.gz"
  mkdir -p "$BUILD_OUTPUT"
  cd "$BUILD_OUTPUT"
  tar -xzf "$SRC/bcm963xx/bcm963xx_5.02L.07p2_consumer.tar.gz"
  patch -p 1 --ignore-whitespace -F 3 < "$SRC/bcm963xx/bcm.patch"
fi

# squashfs-tools 4.2 needs GNU89 inline on GCC 5+
HOSTMK="$BUILD_OUTPUT/hostTools/Makefile"
if [ -f "$HOSTMK" ] && ! grep -q -- '-fgnu89-inline' "$HOSTMK"; then
  sed -i 's/-O2 -DGNU/-O2 -fgnu89-inline -fcommon -DGNU/' "$HOSTMK"
fi

cd "$BUILD_OUTPUT"
make PROFILE=NVG578LX_AX WIFI_AX=1
