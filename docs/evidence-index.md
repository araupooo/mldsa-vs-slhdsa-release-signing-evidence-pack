# Claims-to-evidence index

Each claim maps to an unedited log under `outputs/` or a primary
source in `docs/citations.md`. "Shipped" means the log produced by
`scripts/run_all.sh`; "fresh" means the log produced by
`scripts/clean_reproduce.sh` from a fresh copy (shipped under
`outputs/fresh-clone-*.log`).

## Measured claims

| # | Claim | Evidence |
| --- | --- | --- |
| C1 | ML-DSA-44/65/87 sign/verify/keygen medians and sizes (Table 3) | `outputs/benchmarks-run1.log` (`bench:` lines), `outputs/benchmarks-run1.csv`; repeated in run2 |
| C2 | SLH-DSA-128s/128f/192s/256s sign/verify/keygen medians and sizes (Table 3) | `outputs/benchmarks-run1.log`, `outputs/benchmarks-run1.csv`; repeated in run2 |
| C3 | All 7 parameter sets pass all 8 correctness checks (round-trip, tampered artifact/signature rejected, wrong key rejected, empty-message round-trip, sizes) | `outputs/sign-tests.log` (`test_summary:` + `RESULT: PASS` lines) |
| C4 | Signature/key sizes equal the advertised lengths at runtime | `outputs/sign-tests.log` (`sizes:` lines, printed by the harness from the library) |
| C5 | Signing cost vs artifact size: ML-DSA-65 grows ~linearly (155 µs / 5.3 ms / 52.6 ms for 503 B / 1 MB / 10 MB); SLH-DSA-128s is nearly flat (727 / 725 / 826 ms) | `outputs/scale-run1.csv`, `outputs/benchmarks-run1.log` (`scalesign:` lines); repeated in run2 |
| C6 | Transparency log: 5 entries appended, inclusion proof verifies, tamper changes the root, stale proof rejected | `outputs/tlog-demo.log` (`tlog_summary:` + `RESULT: PASS`) |
| C7 | Key rotation: v1 signs 1.4.2, v2 signs 1.4.3, v1 signature fails under v2, v1 signature still verifies under retired v1 | `outputs/rotation-demo.log` (`RESULT: PASS`), `outputs/rotation-manifest.json` |
| C8 | Fresh-clone run re-derives the same outcomes (tests PASS, benchmarks within a few percent, demos PASS) | `outputs/fresh-clone-run.log` (comparison), `outputs/fresh-clone-*.log` |
| C9 | SLH-DSA `s`-variant keygen is slow (90–137 ms) vs `f`-variant (1.5 ms) | `outputs/benchmarks-run1.log` (`bench:` keygen_median_us), repeated in run2 and fresh clone |

## Specification-derived claims

| # | Claim | Primary source |
| --- | --- | --- |
| S1 | ML-DSA parameter sets, categories 2/3/5, sizes (Table 2) | FIPS 204, Tables 1–2; liboqs `ml_dsa.yml`; runtime `sizes:` lines |
| S2 | SLH-DSA parameter sets, `s` vs `f` trade-off, sizes (Table 2) | FIPS 205, Table 2; liboqs `slh_dsa.yml`; runtime `sizes:` lines |
| S3 | Signing is randomized (hedged); signature bytes vary per run | FIPS 204 §6 / FIPS 205 (randomized signing); observed: fresh-clone signatures differ, outcomes identical |
| S4 | Transparency-log concepts (append-only Merkle tree, inclusion proof, tamper evidence) | RFC 6962 §§2, 2.1.1, 3; demo in `src/tlog_demo.py` |
| S5 | Record canonicalization (sorted JSON keys, no whitespace) | RFC 8259 (JSON data model); subset documented in methodology L4 |
| S6 | ML-DSA-65 is the general-purpose default for release signing | Decision matrix (measured: 142 µs sign, 3,309 B sig, category 3) — a recommendation, not a standard requirement; FIPS 204 designates no default parameter set |

## Findings

Findings F1–F8: `docs/threat-model.md`. Limitations L1–L9:
`docs/methodology.md`. Decision matrix: `docs/decision-matrix.md`.
Key-lifecycle runbook: `docs/key-lifecycle.md`. Transparency-log
design: `docs/tlog-design.md`.
