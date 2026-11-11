#!/bin/bash
# clean_reproduce.sh — verify the documented workflow from a fresh copy.
#
# Copies this repository to a fresh directory, rebuilds the pinned liboqs
# 0.16.0 (optimized build) from fixtures/, rebuilds the harness, and
# re-runs the FULL test suite, the FULL benchmarks (run1 and run2), and
# the FULL demos (transparency log + key rotation). The fresh logs are
# then copied into this pack's outputs/ as outputs/fresh-clone-*.log, and
# a headline comparison (fresh vs shipped) is printed.
#
# Usage: scripts/clean_reproduce.sh [workdir]
#   workdir defaults to a fresh directory under /tmp.
# This takes a full liboqs build (~10 min on a 4-vCPU machine).
set -u
PACK="$(cd "$(dirname "$0")/.." && pwd)"
R="${1:-/tmp/ml-dsa-slh-repro}"
echo "clean_reproduce: workdir=$R"
rm -rf "$R"
mkdir -p "$R"
cp -r "$PACK" "$R/pack"
cd "$R/pack"
mkdir -p work
tar xzf fixtures/liboqs-0.16.0.tar.gz -C work
mv work/liboqs-0.16.0 work/liboqs-0.16.0-src
cmake -S work/liboqs-0.16.0-src -B work/build-opt \
  -DCMAKE_BUILD_TYPE=Release -DOQS_DIST_BUILD=OFF -DOQS_OPT_TARGET=auto \
  -DOQS_BUILD_ONLY_LIB=ON -DCMAKE_INSTALL_PREFIX="$R/pack/work/install-opt" \
  > work/repro-opt-cmake.log 2>&1
cmake --build work/build-opt -j4 > work/repro-opt-make.log 2>&1
cmake --install work/build-opt > work/repro-opt-install.log 2>&1
grep -h OQS_VERSION_TEXT work/install-opt/include/oqs/oqsconfig.h
export WORK="$R/pack/work" OUT="$R/out"
mkdir -p "$OUT"
bash scripts/build_harness.sh
bash scripts/run_tests.sh
bash scripts/run_benchmarks.sh run1
bash scripts/run_benchmarks.sh run2
bash scripts/run_demo.sh
# Ship the fresh logs into this pack's outputs/ (published evidence).
for f in sign-tests.log benchmarks-run1.log benchmarks-run2.log benchmarks-run1.csv benchmarks-run2.csv scale-run1.csv scale-run2.csv tlog-demo.log rotation-demo.log rotation-manifest.json; do
  cp "$OUT/$f" "$PACK/outputs/fresh-clone-$f" 2>/dev/null || true
done
cp work/repro-opt-cmake.log work/repro-opt-make.log work/repro-opt-install.log "$PACK/outputs/" 2>/dev/null || true
# Headline comparison (fresh vs shipped), computed from the logs.
# The comparison is also saved to outputs/fresh-clone-run.log so the
# fresh-clone verification output ships with the pack.
python3 - "$R/out" "$PACK/outputs" << 'PYEOF' | tee "$PACK/outputs/fresh-clone-run.log"
import re, sys
fresh_dir, ship_dir = sys.argv[1], sys.argv[2]

def bench(path):
    d = {}
    try:
        with open(path) as f:
            for line in f:
                m = re.match(r"bench: alg=(\S+) n=\d+ .*sign_median_us=([\d.]+) verify_median_us=([\d.]+)", line)
                if m:
                    d[m.group(1)] = (float(m.group(2)), float(m.group(3)))
    except FileNotFoundError:
        pass
    return d

def result(path, key):
    try:
        with open(path) as f:
            for line in f:
                if line.startswith(key):
                    return line.strip()
    except FileNotFoundError:
        pass
    return "MISSING"

print("=== headline comparison (fresh clone vs shipped) ===")
print("--- sign tests ---")
print("fresh:  ", result(f"{fresh_dir}/sign-tests.log", "RESULT:"))
print("shipped:", result(f"{ship_dir}/sign-tests.log", "RESULT:"))
print("--- benchmarks run1 (sign_median_us / verify_median_us) ---")
fb, sb = bench(f"{fresh_dir}/benchmarks-run1.log"), bench(f"{ship_dir}/benchmarks-run1.log")
for alg in sorted(set(fb) | set(sb)):
    f, s = fb.get(alg), sb.get(alg)
    if f and s:
        ds = 100 * (f[0] - s[0]) / s[0] if s[0] else 0
        dv = 100 * (f[1] - s[1]) / s[1] if s[1] else 0
        print(f"{alg}: fresh sign={f[0]:.1f}us verify={f[1]:.1f}us | shipped sign={s[0]:.1f}us verify={s[1]:.1f}us | diff {ds:+.1f}% / {dv:+.1f}%")
    else:
        print(f"{alg}: fresh={f} shipped={s}")
print("--- transparency-log demo ---")
print("fresh:  ", result(f"{fresh_dir}/tlog-demo.log", "RESULT:"))
print("shipped:", result(f"{ship_dir}/tlog-demo.log", "RESULT:"))
print("--- key-rotation demo ---")
print("fresh:  ", result(f"{fresh_dir}/rotation-demo.log", "RESULT:"))
print("shipped:", result(f"{ship_dir}/rotation-demo.log", "RESULT:"))
PYEOF
echo "clean_reproduce.sh DONE (workdir kept at $R)" | tee -a "$PACK/outputs/fresh-clone-run.log"
