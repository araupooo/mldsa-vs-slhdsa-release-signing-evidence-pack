# Methodology

## What was measured, and how

All measurements were produced by the runnable harness in `src/`
against the pinned liboqs 0.16.0 build (single optimized build,
`OQS_OPT_TARGET=auto`; see L1). The harness signs and verifies the
committed release artifact `fixtures/release-1.4.2.tar.gz` (503 bytes,
SHA256 `ac4c6d211d5b59513a3f83114f01ec35ade674e5f596e7a612a5516845c3eb2d`)
and deterministic large files regenerated at runtime
(`work/large/large-1mb.bin`, `large-10mb.bin`, seeded PRNG `0xC0FFEE`).

- **Correctness** (`scripts/run_tests.sh` → `outputs/sign-tests.log`):
  for each of 7 parameter sets (ML-DSA-44/65/87,
  SLH-DSA-SHA2-128s/128f/192s/256s), key generation, sign/verify
  round-trip, tampered-artifact rejection, tampered-signature
  rejection, wrong-key rejection, empty-message round-trip, and a
  check that produced signature lengths equal the advertised lengths.
- **Benchmarks** (`scripts/run_benchmarks.sh run1|run2` →
  `outputs/benchmarks-run*.log`, `*.csv`): keygen/sign/verify medians
  over a fixed N (100 ops for ML-DSA, 20 for SLH-DSA — SLH-DSA signing
  is slow enough that 100 ops would dominate the run), plus
  artifact-size scaling (sign the 503-byte tarball, a 1 MB file, and a
  10 MB file; N=20/5/5). Medians are the robust comparison; means are
  not reported for timings because VM scheduling spikes dominate them.
- **Demos** (`scripts/run_demo.sh` → `outputs/tlog-demo.log`,
  `outputs/rotation-demo.log`, `outputs/rotation-manifest.json`):
  a Merkle-tree transparency log over 5 signed release records
  (inclusion proof verified; tamper detected), and a key-rotation
  walk-through (v1 signs release 1.4.2, v2 signs 1.4.3, cross-key
  verification fails, old signatures stay valid under the retired key).
- **Reproduction** (`scripts/clean_reproduce.sh`): copies the pack to a
  fresh directory, rebuilds liboqs from `fixtures/`, and re-runs the
  FULL test suite, FULL benchmarks (run1 and run2), and FULL demos.
  Fresh logs are shipped under `outputs/fresh-clone-*.log` and a
  headline comparison is printed (`outputs/fresh-clone-run.log`).

## What counts as evidence

- A measured claim is backed by an unedited log under `outputs/`
  produced by a script in `scripts/`. The log header records the
  artifact SHA256 and the UTC start time.
- A specification-derived claim cites a primary source in
  `docs/citations.md` and is cross-checked against the implementation
  where possible (e.g. every size claim is printed at runtime by the
  harness `sizes` command and appears in `outputs/sign-tests.log`).
- `docs/evidence-index.md` maps each claim to its log file or source.

## Environment

See `fixtures/environment.txt` (machine, CPU, compiler, CMake,
Python, liboqs version, dependency statement). All runs on the same
shared 4-vCPU virtual machine; background load inflates latency
outliers, which is why medians are reported.

## Limitations

- **L1 — Single build configuration.** Only the optimized liboqs
  build (`OQS_OPT_TARGET=auto`, AVX2) was measured. A reference
  (`generic`) build was not run: the numbers describe the optimized
  build on this machine, not the algorithm's portable reference
  performance. The build flags are recorded in the build logs.
- **L2 — Timing noise.** Single shared virtual machine. Medians over
  100 (ML-DSA) / 20 (SLH-DSA) ops are the robust comparison; maxima
  and means are not reported. Run-to-run variation is shown by
  comparing run1, run2, and the fresh-clone run.
- **L3 — Randomized signatures.** ML-DSA and SLH-DSA signing is
  randomized (hedged) per FIPS 204/205, so signature bytes differ
  between runs. Tests assert on verification outcomes and lengths,
  never on fixed signature bytes. The fresh-clone run therefore
  re-derives the same outcomes, not the same bytes.
- **L4 — Canonicalization subset.** Transparency-log records are
  canonicalized with sorted JSON keys and no whitespace — a
  deterministic subset, not full JCS (RFC 8785). Non-ASCII strings
  and floats do not occur in records; the subset is sufficient for
  this demo and is not claimed to be JCS.
- **L5 — Transparency log is local.** The demo log is a single-operator,
  in-memory Merkle tree with no external auditors, gossip, or signed
  tree heads. It demonstrates the append-only / inclusion-proof /
  tamper-detection mechanics, not a production transparency
  infrastructure (cf. RFC 6962).
- **L6 — Hardware-backed signing not tested.** No HSM or secure
  enclave was available on this VM. The runbook's hardware-backed
  options are documented from vendor/docs sources only and are
  labelled as not tested here.
- **L7 — Parameter-set coverage.** SLH-DSA coverage is the SHA-2
  `s`/`f` sets at 128/192/256 (128s, 128f, 192s, 256s). SHAKE
  variants and prehash variants were not measured; their sizes are
  identical to the SHA-2 counterparts per FIPS 205 Table 2 and were
  not re-verified here.
- **L8 — Single artifact shape.** Benchmarks sign one small tarball
  and two synthetic large files. Real release trees vary; the scaling
  measurements show the per-byte cost trend, not a guarantee for an
  arbitrary artifact.
- **L9 — Revocation enforcement is procedural.** The harness does not
  implement a revocation list; the runbook's revocation step is a
  documented procedure (publish the revocation record, append it to
  the transparency log). A verifier that ignores the revocation record
  would still cryptographically verify a revoked key's signatures.
