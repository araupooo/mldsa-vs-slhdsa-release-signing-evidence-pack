#!/bin/bash
# make_artifacts.sh — build the deterministic sample release artifacts.
#
# Creates, under $OUTDIR (default: fixtures/ when run from the pack root,
# or work/artifacts/ for runtime-generated files):
#   release-1.4.2.tar.gz   a small real tarball of dummy release sources
#   release-1.4.2-manifest.json  name/version/files with sha256
#   release-1.4.2.sha256   checksums file (sha256sum format)
#
# The large scaling files (large-1mb.bin / large-10mb.bin) are NOT
# committed: run_benchmarks.sh regenerates them deterministically into
# work/large/ at runtime (same seeded PRNG).
#
# The tarball is reproducible: fixed mtimes, owner/group, sorted entries.
# Usage: scripts/make_artifacts.sh [outdir]
set -eu
PACK="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$PACK/fixtures}"
# Canonicalize OUT to an absolute path: the script cds below.
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
mkdir -p "$OUT" "$PACK/../work/artifacts-src"
cd "$PACK/../work/artifacts-src"
rm -rf release-1.4.2
mkdir -p release-1.4.2/src release-1.4.2/docs
cat > release-1.4.2/src/main.c << 'EOF'
/* example release 1.4.2 — dummy source file, part of the signed artifact */
#include <stdio.h>
int main(void) { printf("example release 1.4.2\n"); return 0; }
EOF
cat > release-1.4.2/src/util.c << 'EOF'
/* example release 1.4.2 — dummy utility source */
int util_add(int a, int b) { return a + b; }
EOF
cat > release-1.4.2/docs/README.txt << 'EOF'
Example release 1.4.2
This is a sample release artifact used by the release-signing harness.
It is a real tarball with real files, built deterministically.
EOF
cat > release-1.4.2/VERSION << 'EOF'
1.4.2
EOF
find release-1.4.2 -exec touch -d "2026-11-01 00:00:00 UTC" {} +
tar --sort=name --owner=0 --group=0 --numeric-owner -czf "$OUT/release-1.4.2.tar.gz" release-1.4.2
python3 - "$OUT" << 'PYEOF'
import hashlib, json, os, random, sys
out = sys.argv[1]
tar = os.path.join(out, "release-1.4.2.tar.gz")
with open(tar, "rb") as f:
    data = f.read()
sha = hashlib.sha256(data).hexdigest()
manifest = {
    "name": "example-release",
    "version": "1.4.2",
    "files": [{"name": "release-1.4.2.tar.gz", "bytes": len(data), "sha256": sha}],
}
with open(os.path.join(out, "release-1.4.2-manifest.json"), "w") as f:
    json.dump(manifest, f, indent=2, sort_keys=True)
    f.write("\n")
with open(os.path.join(out, "release-1.4.2.sha256"), "w") as f:
    f.write(f"{sha}  release-1.4.2.tar.gz\n")
print(f"artifacts: tarball_bytes={len(data)} sha256={sha}")
PYEOF
