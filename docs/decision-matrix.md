# Release-signing decision matrix — ML-DSA vs SLH-DSA

All numbers are measured medians from `outputs/benchmarks-run1.log`
(run2 agrees within a few percent; see `docs/index.html` Table 3).
Sizes are from FIPS 204 Table 2 / FIPS 205 Table 2, printed at runtime
by the harness (`outputs/sign-tests.log`, `sizes:` lines).
Artifact for benchmarks: `fixtures/release-1.4.2.tar.gz` (503 bytes),
plus 1 MB / 10 MB scaling files.

## Measured reference table (run1 medians)

| Parameter set | Category | pk (B) | sk (B) | sig (B) | keygen | sign | verify |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ML-DSA-44 | 2 | 1,312 | 2,560 | 2,420 | 32.6 µs | 83.4 µs | 37.4 µs |
| ML-DSA-65 | 3 | 1,952 | 4,032 | 3,309 | 56.9 µs | 142.2 µs | 60.3 µs |
| ML-DSA-87 | 5 | 2,592 | 4,896 | 4,627 | 82.1 µs | 161.9 µs | 85.2 µs |
| SLH-DSA-SHA2-128s | 1 | 32 | 64 | 7,856 | 95.5 ms | 720.2 ms | 709 µs |
| SLH-DSA-SHA2-128f | 1 | 32 | 64 | 17,088 | 1.5 ms | 34.6 ms | 2,159 µs |
| SLH-DSA-SHA2-192s | 3 | 48 | 96 | 16,224 | 137.1 ms | 1,269.1 ms | 988 µs |
| SLH-DSA-SHA2-256s | 5 | 64 | 128 | 29,792 | 90.0 ms | 1,127.4 ms | 1,589 µs |

Notes:
- SLH-DSA `s` key generation is slow (90–137 ms) because keygen
  computes the top XMSS tree; `f` keygen is fast (1.5 ms) because the
  top tree is tiny. This is an implementation property of the hypertree
  parameters, not a measurement error — run2 reproduces it
  (128s keygen 93.8 ms, 128f 1.5 ms).
- SLH-DSA signing cost is nearly independent of artifact size
  (128s: 727 ms at 503 B, 725 ms at 1 MB, 826 ms at 10 MB), because the
  message is hashed once and the hypertree work dominates. ML-DSA
  signing grows linearly with artifact size (65: 155 µs at 503 B,
  5.3 ms at 1 MB, 52.6 ms at 10 MB) — hashing dominates. Even at
  10 MB, ML-DSA-65 signs ~16x faster than SLH-DSA-128s.

## Use-case recommendations

| Use case | Recommendation | Why (measured) |
| --- | --- | --- |
| Frequent small releases (many signatures/day) | **ML-DSA-65** (or 44 for category 2) | Sign 142 µs vs 720 ms for SLH-DSA-128s (~5,000x faster); sig 3,309 B vs 7,856 B. |
| Large artifacts (10 MB+) | **ML-DSA-65** | Sign 52.6 ms at 10 MB vs 826 ms for SLH-DSA-128s; still ~16x faster, and the signature is 2.4x smaller. |
| Long-lived signatures / hedge against a lattice break | **SLH-DSA-128s** (or 192s/256s for higher categories) | Security rests only on hash functions (FIPS 205), not on lattices. Cost: 720 ms/sign, 7,856 B signatures; verification is cheap (709 µs), so verify-heavy use is fine. |
| Constrained verifiers / bandwidth-sensitive distribution | **ML-DSA-44** | Smallest signature measured (2,420 B), fastest verify (37 µs). SLH-DSA signatures (7,856–29,792 B) are 3–12x larger. |
| High-volume verification (many verifiers per release) | **ML-DSA** (any set) | Verify 37–85 µs vs SLH-DSA 709–2,159 µs (~10–20x faster). |
| Frequent key rotation | **ML-DSA** or **SLH-DSA-`f`** | ML-DSA keygen 33–82 µs; SLH-DSA-128f keygen 1.5 ms. Avoid SLH-DSA-`s` for frequent rotation (keygen 90–137 ms). |
| Within SLH-DSA: signing throughput matters | **128f** over **128s** | Sign 34.6 ms vs 720.2 ms (21x faster); keygen 1.5 ms vs 95.5 ms. Trade-off: signature 17,088 B vs 7,856 B (2.2x larger) and verify 2,159 µs vs 709 µs. |
| Within SLH-DSA: signature size matters | **128s** over **128f** | Signature 7,856 B vs 17,088 B; same 32-byte public key and category 1. Trade-off: 720 ms signing. |
| Maximum security category (5) | **ML-DSA-87** for speed, **SLH-DSA-256s** for hash-only assumptions | 87: sign 162 µs, sig 4,627 B. 256s: sign 1,127 ms, sig 29,792 B. Both category 5. |

## What the matrix does not decide

- **Regulatory requirements** (e.g. CNSA 2.0 timelines) are out of
  scope: this matrix is a performance/size engineering comparison, not
  a compliance recommendation.
- **Ecosystem support** (tooling, HSM firmware, package managers)
  varies by vendor and date; the runbook's hardware section
  (`docs/key-lifecycle.md`) is documentation-only and was not tested.
- **Hybrid signatures** (classical + PQC in one release) are not
  measured here. If a migration requires them, measure the combined
  sizes and timings separately — do not add the two schemes' numbers
  without measuring the combiner.
