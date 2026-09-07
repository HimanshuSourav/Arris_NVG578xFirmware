#!/usr/bin/env bash
# Idempotent host setup for building NVG578LX_AX firmware from the SourceForge OSS release.
# Designed for Ubuntu 24.04 Cloud Agent VMs (README documents Ubuntu 20.04).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
PERLBREW_ROOT="${PERLBREW_ROOT:-$HOME/perl5/perlbrew}"
SRC_DIR="${NVG578_SRC_DIR:-$(cd "$(dirname "$0")/.." && pwd)/nvg578.9.5.0h4}"

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y \
  build-essential automake gcc-multilib \
  libc6:i386 libstdc++6:i386 libelf1t64:i386 libncurses6:i386 libtinfo6:i386 \
  liblzo2-dev uuid-dev quilt gawk flex xutils-dev bison byacc \
  pkg-config python-is-python3 cmake cpio gettext wget \
  mtd-utils zlib1g-dev libtool bc rsync unzip \
  libncurses-dev texinfo file python3-dev xxd \
  perlbrew cpanminus

# Ubuntu 20.04 ncurses5 SONAME (removed from 24.04; required by 32-bit vendor tools)
if ! ldconfig -p 2>/dev/null | grep -q 'libncurses\.so\.5'; then
  tmp=$(mktemp -d)
  (
    cd "$tmp"
    for deb in \
      libtinfo5_6.2-0ubuntu2.1_amd64.deb \
      libtinfo5_6.2-0ubuntu2.1_i386.deb \
      libncurses5_6.2-0ubuntu2.1_amd64.deb \
      libncurses5_6.2-0ubuntu2.1_i386.deb; do
      wget -q "http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/${deb}"
    done
    sudo dpkg -i libtinfo5_*.deb libncurses5_*.deb
  )
  rm -rf "$tmp"
fi

# t64 transition: old binaries look for libelf.so.1
if [ ! -e /usr/lib/i386-linux-gnu/libelf.so.1 ] && [ -e /usr/lib/i386-linux-gnu/libelf.so.1t64 ]; then
  sudo ln -sf libelf.so.1t64 /usr/lib/i386-linux-gnu/libelf.so.1
fi
if [ ! -e /usr/lib/x86_64-linux-gnu/libelf.so.1 ] && [ -e /usr/lib/x86_64-linux-gnu/libelf.so.1t64 ]; then
  sudo ln -sf libelf.so.1t64 /usr/lib/x86_64-linux-gnu/libelf.so.1
fi

# Broadcom host tools expect /bin/sh to be bash, not dash
if [ "$(readlink -f /bin/sh)" != "/usr/bin/bash" ] && [ "$(readlink -f /bin/sh)" != "/bin/bash" ]; then
  sudo ln -sf bash /bin/sh
fi

grep -q '^LANG=' /etc/environment 2>/dev/null || echo 'LANG=en_US.UTF-8' | sudo tee -a /etc/environment >/dev/null

# Perl 5.22.1 as required by the vendor README
if [ ! -x "$PERLBREW_ROOT/bin/perlbrew" ]; then
  curl -fsSL https://install.perlbrew.pl | bash
fi
# shellcheck disable=SC1091
source "$PERLBREW_ROOT/etc/bashrc"
if ! perlbrew list | grep -q 'perl-5.22.1'; then
  perlbrew --notest install perl-5.22.1 -j"$(nproc)"
fi
perlbrew switch perl-5.22.1
if [ ! -x "$PERLBREW_ROOT/bin/cpanm" ]; then
  perlbrew install-cpanm
fi
perl -MConvert::Binary::C -e 1 2>/dev/null || cpanm --notest Convert::Binary::C
perl -MDigest::CRC -e 1 2>/dev/null || cpanm --notest Digest::CRC

grep -q 'perlbrew/etc/bashrc' "$HOME/.bashrc" 2>/dev/null || echo 'source "$HOME/perl5/perlbrew/etc/bashrc"' >> "$HOME/.bashrc"
grep -q 'perlbrew/etc/bashrc' "$HOME/.profile" 2>/dev/null || echo 'source "$HOME/perl5/perlbrew/etc/bashrc"' >> "$HOME/.profile"

# Host gcc wrappers are NOT added to PATH (they break cross autoconf).
# scripts/build-nvg578.sh injects -fgnu89-inline into hostTools/Makefile instead.

# Vendor toolchains (ARC / ARM / aarch64)
if [ -d "$SRC_DIR/toolchains" ]; then
  if [ ! -d /usr/local/ARC/arcp1 ]; then
    sudo sh "$SRC_DIR/toolchains/QEnvInstaller-v1.1.bin" --nox11 --noprogress
  fi
  if [ ! -d /opt/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1 ]; then
    sudo tar --absolute-names -xjf "$SRC_DIR/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1.Rel1.10.tar.bz2" -C /
  fi
  if [ ! -d /opt/toolchains/crosstools-aarch64-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1 ]; then
    sudo mkdir -p /opt/toolchains
    sudo tar -xf "$SRC_DIR/toolchains/crosstools-aarch64-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1.tar.bz2" -C /opt/toolchains
  fi
fi

echo "Host setup complete."
echo "  perl: $(perl -e 'print $^V')"
echo "  sh -> $(readlink -f /bin/sh)"
echo "  arm gcc: $(ls /opt/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/bin/arm-linux-gcc 2>/dev/null || echo missing)"
