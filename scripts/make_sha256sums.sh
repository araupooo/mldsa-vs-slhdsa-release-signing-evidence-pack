#!/bin/bash
# make_sha256sums.sh — regenerate SHA256SUMS over all pack files
# (excluding SHA256SUMS itself). Run from the pack root.
set -eu
PACK="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PACK"
find . -type f ! -name SHA256SUMS ! -path "./work/*" | sort | xargs sha256sum > SHA256SUMS
echo "wrote SHA256SUMS ($(wc -l < SHA256SUMS) files)"
