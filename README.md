# ML-DSA vs SLH-DSA Release-Signing Assessment

A runnable comparison of the two NIST post-quantum signature standards
(FIPS 204 ML-DSA, FIPS 205 SLH-DSA) for software release signing, with
measured timings and sizes, a use-case decision matrix, a key-lifecycle
runbook, and a working transparency-log demo.

## Headline

Both schemes sign and verify real release artifacts: 56/56 correctness
checks pass across 7 parameter sets. ML-DSA-65 is the general-purpose
default (142 µs sign, 3,309-byte signature, category 3). SLH-DSA-128s
is the hash-only hedge (720 ms sign, 7,856-byte signature, category 1).
Full tables: `docs/index.html`.

## Layout

- `src/release_sign.c` — signing harness (liboqs OQS_SIG API): keygen,
  sign, verify, bench, test, scalesign.
- `src/tlog_demo.py` — append-only Merkle-tree transparency-log demo.
- `scripts/run_tests.sh` — correctness suite (8 checks × 7 parameter sets).
- `scripts/run_benchmarks.sh [run1|run2]` — timings, sizes, scaling.
- `scripts/run_demo.sh` — transparency-log + key-rotation demos.
- `scripts/run_all.sh` — everything, then the manifest.
- `scripts/clean_reproduce.sh` — fresh-copy full re-run; fresh logs
  ship under `outputs/fresh-clone-*.log`.
- `scripts/verify_digests.sh` — SHA256SUMS check over all pack files.
- `docs/` — findings page (`index.html`), methodology, decision matrix,
  key-lifecycle runbook, transparency-log design, threat model,
  claims-to-evidence index, citations.
- `fixtures/` — pinned liboqs 0.16.0 tarball (+SHA256), the release
  artifact (`release-1.4.2.tar.gz`, 503 bytes), environment details.
- `outputs/` — unedited logs, CSVs, manifests. Test keys are generated
  at runtime and never committed.

## Quick start

```sh
# Build liboqs 0.16.0 (optimized) from fixtures/:
tar xzf fixtures/liboqs-0.16.0.tar.gz -C work
mv work/liboqs-0.16.0 work/liboqs-0.16.0-src
cmake -S work/liboqs-0.16.0-src -B work/build-opt \
  -DCMAKE_BUILD_TYPE=Release -DOQS_DIST_BUILD=OFF -DOQS_OPT_TARGET=auto \
  -DOQS_BUILD_ONLY_LIB=ON -DCMAKE_INSTALL_PREFIX="$PWD/work/install-opt"
cmake --build work/build-opt -j4 && cmake --install work/build-opt

# Then run everything:
bash scripts/run_all.sh
# Or the fresh-clone verification:
bash scripts/clean_reproduce.sh
# Verify digests:
bash scripts/verify_digests.sh
```

## Environment

GCC 13.3.0, CMake 3.28.3, Python 3.12.3, liboqs 0.16.0, 4-vCPU Linux
(see `fixtures/environment.txt`). No third-party Python packages; no
network access during build/run.
