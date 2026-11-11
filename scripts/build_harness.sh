#!/bin/bash
# build_harness.sh — compile src/release_sign.c against the pinned liboqs
# install. WORK defaults to $PACK/work; INSTALL defaults to $WORK/install-opt.
# Usage: WORK=<workdir> bash scripts/build_harness.sh
set -eu
PACK="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$PACK/../work}"
INSTALL="${INSTALL:-$WORK/install-opt}"
mkdir -p "$WORK/bin"
cc -O2 -I"$INSTALL/include" "$PACK/src/release_sign.c" \
   -L"$INSTALL/lib" -loqs -lcrypto -o "$WORK/bin/release_sign"
echo "built: $WORK/bin/release_sign"
ls -l "$WORK/bin/release_sign"
