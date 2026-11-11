#!/bin/bash
# run_tests.sh — correctness suite for every parameter set.
# Signs and verifies the committed release artifact (fixtures/) with each
# algorithm; each test checks round-trip, tampered-artifact rejection,
# tampered-signature rejection, wrong-key rejection, empty-message
# round-trip, and advertised sizes. Writes the unedited log to
# outputs/sign-tests.log. Exit code 0 iff every check passes.
set -u
PACK="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$PACK/../work}"
OUT="${OUT:-$PACK/outputs}"
HARNESS="$WORK/bin/release_sign"
ARTIFACT="$PACK/fixtures/release-1.4.2.tar.gz"
mkdir -p "$OUT"
if [ ! -x "$HARNESS" ]; then WORK="$WORK" bash "$PACK/scripts/build_harness.sh"; fi
[ -x "$HARNESS" ] || { echo "error: harness not built (missing liboqs install in $WORK/install-opt? run scripts/clean_reproduce.sh or build liboqs first)"; exit 1; }
[ -f "$ARTIFACT" ] || { echo "missing artifact: $ARTIFACT"; exit 1; }
echo "sign-tests: artifact=$ARTIFACT sha256=$(sha256sum "$ARTIFACT" | cut -d' ' -f1)"
echo "sign-tests: utc_start=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ALGS="ML-DSA-44 ML-DSA-65 ML-DSA-87 SLH_DSA_PURE_SHA2_128S SLH_DSA_PURE_SHA2_128F SLH_DSA_PURE_SHA2_192S SLH_DSA_PURE_SHA2_256S"
{
echo "sign-tests: artifact=$ARTIFACT sha256=$(sha256sum "$ARTIFACT" | cut -d' ' -f1)"
echo "sign-tests: utc_start=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fail=0
for alg in $ALGS; do
  echo "--- $alg ---"
  "$HARNESS" sizes "$alg"
  if ! "$HARNESS" test "$alg" "$ARTIFACT"; then fail=1; fi
done
echo "sign-tests: utc_end=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [ "$fail" -eq 0 ]; then echo "RESULT: PASS sign-tests all_algorithms"; else echo "RESULT: FAIL sign-tests"; fi
} | tee "$OUT/sign-tests.log"
grep -q "RESULT: PASS" "$OUT/sign-tests.log"
