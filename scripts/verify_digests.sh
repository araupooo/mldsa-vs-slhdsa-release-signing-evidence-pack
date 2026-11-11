#!/bin/bash
# verify_digests.sh — verify SHA256SUMS over all pack files.
# Usage: scripts/verify_digests.sh  (run from anywhere; resolves pack root)
set -u
PACK="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PACK"
sha256sum -c SHA256SUMS
