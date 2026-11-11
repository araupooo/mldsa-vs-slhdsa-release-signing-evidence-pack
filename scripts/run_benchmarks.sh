#!/bin/bash
# run_benchmarks.sh — sign/verify/keygen timings and sizes per parameter set.
# Usage: scripts/run_benchmarks.sh [run1|run2]   (default run1)
# Writes unedited logs to outputs/benchmarks-<tag>.log and raw results to
# outputs/benchmarks-<tag>.csv (bench) and outputs/scale-<tag>.csv.
# ML-DSA uses n=100 sign/verify ops; SLH-DSA uses n=20 (signing is slower).
# Artifact-size scaling signs the 1 MB and 10 MB deterministic files (n=5).
set -u
PACK="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$PACK/../work}"
OUT="${OUT:-$PACK/outputs}"
TAG="${1:-run1}"
HARNESS="$WORK/bin/release_sign"
ARTIFACT="$PACK/fixtures/release-1.4.2.tar.gz"
mkdir -p "$OUT" "$WORK/large"
if [ ! -x "$HARNESS" ]; then WORK="$WORK" bash "$PACK/scripts/build_harness.sh"; fi
[ -x "$HARNESS" ] || { echo "error: harness not built (missing liboqs install in $WORK/install-opt? run scripts/clean_reproduce.sh or build liboqs first)"; exit 1; }
[ -f "$ARTIFACT" ] || { echo "missing artifact: $ARTIFACT"; exit 1; }
# Deterministic large files (seeded PRNG) for size scaling.
python3 - "$WORK/large" << 'PYEOF'
import random, os, sys
out = sys.argv[1]
for name, size in (("large-1mb.bin", 1 << 20), ("large-10mb.bin", 10 << 20)):
    p = os.path.join(out, name)
    if os.path.exists(p) and os.path.getsize(p) == size:
        continue
    rng = random.Random(0xC0FFEE)
    chunk = bytes(rng.randrange(256) for _ in range(1 << 20))
    with open(p, "wb") as f:
        for _ in range(size >> 20):
            f.write(chunk)
PYEOF
{
echo "benchmarks: tag=$TAG artifact=$ARTIFACT sha256=$(sha256sum "$ARTIFACT" | cut -d' ' -f1)"
echo "benchmarks: utc_start=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "benchmarks: csv header: alg,n,artifact_bytes,pk_len,sk_len,sig_len,keygen_median_us,sign_median_us,verify_median_us,verify_ok"
for alg in ML-DSA-44 ML-DSA-65 ML-DSA-87; do
  "$HARNESS" bench "$alg" "$ARTIFACT" 100
done
for alg in SLH_DSA_PURE_SHA2_128S SLH_DSA_PURE_SHA2_128F SLH_DSA_PURE_SHA2_192S SLH_DSA_PURE_SHA2_256S; do
  "$HARNESS" bench "$alg" "$ARTIFACT" 20
done
echo "--- artifact-size scaling (sign only) ---"
for alg in ML-DSA-65 SLH_DSA_PURE_SHA2_128S; do
  "$HARNESS" scalesign "$alg" "$ARTIFACT" 20
  "$HARNESS" scalesign "$alg" "$WORK/large/large-1mb.bin" 5
  "$HARNESS" scalesign "$alg" "$WORK/large/large-10mb.bin" 5
done
echo "benchmarks: utc_end=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "RESULT: PASS benchmarks tag=$TAG"
} | tee "$OUT/benchmarks-$TAG.log"
grep "^csv: " "$OUT/benchmarks-$TAG.log" | sed 's/^csv: //' > "$OUT/benchmarks-$TAG.csv"
{ echo "alg,artifact_bytes,n,sign_median_us,sig_len"; grep "^scalesign: " "$OUT/benchmarks-$TAG.log" | awk '{print $2" "$3" "$4" "$5" "$6}' | sed -E 's/alg=([^ ]+) artifact_bytes=([0-9]+) n=([0-9]+) sign_median_us=([0-9.]+) sig_len=([0-9]+)/\1,\2,\3,\4,\5/'; } > "$OUT/scale-$TAG.csv"
echo "wrote $OUT/benchmarks-$TAG.log $OUT/benchmarks-$TAG.csv $OUT/scale-$TAG.csv"
