#!/bin/bash
# run_all.sh — run the complete workflow: tests, benchmarks (run1 + run2),
# demos, then build logs + manifest. Unedited logs land in outputs/.
# Usage: scripts/run_all.sh
set -eu
PACK="$(cd "$(dirname "$0")/.." && pwd)"
export WORK="${WORK:-$PACK/../work}"
export OUT="${OUT:-$PACK/outputs}"
mkdir -p "$OUT"
bash "$PACK/scripts/build_harness.sh"
bash "$PACK/scripts/run_tests.sh"
bash "$PACK/scripts/run_benchmarks.sh" run1
bash "$PACK/scripts/run_benchmarks.sh" run2
bash "$PACK/scripts/run_demo.sh"
# Ship the liboqs build logs with the outputs (they are evidence too).
cp "$WORK/build-opt-cmake.log" "$WORK/build-opt-make.log" "$WORK/build-opt-install.log" "$OUT/" 2>/dev/null || true
python3 "$PACK/scripts/make_manifest.py"
echo "run_all.sh DONE"
