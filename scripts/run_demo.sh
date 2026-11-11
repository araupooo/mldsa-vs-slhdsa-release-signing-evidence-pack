#!/bin/bash
# run_demo.sh — transparency-log demo + key-rotation demo.
# Writes unedited logs to outputs/tlog-demo.log and outputs/rotation-demo.log,
# and the rotation manifest (key ids, algs, status, public-key prefixes) to
# outputs/rotation-manifest.json. Keys are generated at runtime in work/
# and never committed. Exit code 0 iff both demos pass.
set -u
PACK="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$PACK/../work}"
OUT="${OUT:-$PACK/outputs}"
HARNESS="$WORK/bin/release_sign"
ARTIFACT="$PACK/fixtures/release-1.4.2.tar.gz"
mkdir -p "$OUT" "$WORK/demo"
if [ ! -x "$HARNESS" ]; then WORK="$WORK" bash "$PACK/scripts/build_harness.sh"; fi
[ -x "$HARNESS" ] || { echo "error: harness not built (missing liboqs install in $WORK/install-opt? run scripts/clean_reproduce.sh or build liboqs first)"; exit 1; }
[ -f "$ARTIFACT" ] || { echo "missing artifact: $ARTIFACT"; exit 1; }

# --- Transparency log demo (ML-DSA-65, 5 signed release records) ---
echo "demo: running transparency-log demo (ML-DSA-65, 5 entries)"
python3 "$PACK/src/tlog_demo.py" --harness "$HARNESS" --alg ML-DSA-65 \
  --artifact "$ARTIFACT" --workdir "$WORK/demo/tlog" --entries 5 \
  | tee "$OUT/tlog-demo.log"
grep -q "RESULT: PASS" "$OUT/tlog-demo.log" || { echo "tlog demo FAILED"; exit 1; }

# --- Key rotation demo (ML-DSA-65) ---
echo "demo: running key-rotation demo (ML-DSA-65)"
{
echo "rotation: utc_start=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "rotation: artifact=$ARTIFACT"
K1="$WORK/demo/rot-v1"; K2="$WORK/demo/rot-v2"
mkdir -p "$K1" "$K2"
echo "--- generate key v1 (key_id=release-2026-11-mldsa65-v1) ---"
"$HARNESS" keygen ML-DSA-65 "$K1/pk.bin" "$K1/sk.bin"
echo "--- sign release 1.4.2 with v1 ---"
"$HARNESS" sign ML-DSA-65 "$K1/sk.bin" "$ARTIFACT" "$K1/release-1.4.2.sig"
"$HARNESS" verify ML-DSA-65 "$K1/pk.bin" "$ARTIFACT" "$K1/release-1.4.2.sig" && echo "rotation: v1 signature verifies with v1 key: OK"
echo "--- rotate: generate key v2 (key_id=release-2026-11-mldsa65-v2) ---"
"$HARNESS" keygen ML-DSA-65 "$K2/pk.bin" "$K2/sk.bin"
echo "--- sign release 1.4.3 (same artifact bytes) with v2 ---"
"$HARNESS" sign ML-DSA-65 "$K2/sk.bin" "$ARTIFACT" "$K2/release-1.4.3.sig"
"$HARNESS" verify ML-DSA-65 "$K2/pk.bin" "$ARTIFACT" "$K2/release-1.4.3.sig" && echo "rotation: v2 signature verifies with v2 key: OK"
echo "--- cross-checks: old signatures must NOT verify under the new key ---"
if "$HARNESS" verify ML-DSA-65 "$K2/pk.bin" "$ARTIFACT" "$K1/release-1.4.2.sig"; then
  echo "rotation: FAIL v1 signature verified under v2 key (must not)"
  echo "RESULT: FAIL rotation"; exit 1
else
  echo "rotation: v1 signature under v2 key rejected: OK"
fi
echo "--- v1 signature still verifies under the retired v1 key (old releases stay valid) ---"
"$HARNESS" verify ML-DSA-65 "$K1/pk.bin" "$ARTIFACT" "$K1/release-1.4.2.sig" && echo "rotation: v1 signature verifies with retired v1 key: OK"
PK1_PREFIX=$(od -An -tx1 -N16 "$K1/pk.bin" | tr -d ' \n')
PK2_PREFIX=$(od -An -tx1 -N16 "$K2/pk.bin" | tr -d ' \n')
cat > "$OUT/rotation-manifest.json" << EOF
{
  "alg": "ML-DSA-65",
  "artifact": "release-1.4.2.tar.gz",
  "keys": [
    {"key_id": "release-2026-11-mldsa65-v1", "status": "retired", "pk_prefix_hex": "$PK1_PREFIX", "signed": ["release-1.4.2"]},
    {"key_id": "release-2026-11-mldsa65-v2", "status": "active", "pk_prefix_hex": "$PK2_PREFIX", "signed": ["release-1.4.3"]}
  ]
}
EOF
echo "rotation: manifest written to outputs/rotation-manifest.json"
echo "rotation: utc_end=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "RESULT: PASS rotation"
} | tee "$OUT/rotation-demo.log"
grep -q "RESULT: PASS" "$OUT/rotation-demo.log"
