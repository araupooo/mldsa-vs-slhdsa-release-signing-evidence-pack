# Primary sources

Every specification-derived claim in this pack traces to one of these
sources. Measured claims trace to unedited logs under `outputs/`
(see `docs/evidence-index.md`).

## Standards

- **FIPS 204, *Module-Lattice-Based Digital Signature Standard***, NIST,
  13 August 2024 — https://csrc.nist.gov/pubs/fips/204/final
  Normative for ML-DSA: parameter sets ML-DSA-44/65/87 (Table 1),
  key and signature sizes (Table 2), security categories 2/3/5
  (§4), and the randomized (hedged) signing behaviour used by the
  harness. Sizes used here: 44: pk 1312 / sk 2560 / sig 2420;
  65: 1952 / 4032 / 3309; 87: 2592 / 4896 / 4627 bytes.
- **FIPS 205, *Stateless Hash-Based Digital Signature Standard***, NIST,
  13 August 2024 — https://csrc.nist.gov/pubs/fips/205/final
  Normative for SLH-DSA (standardized SPHINCS+): parameter sets,
  key and signature sizes (Table 2), and the `s` (small signature)
  vs `f` (fast signing) trade-off. Sizes used here (SHA-2 variants):
  128s: pk 32 / sk 64 / sig 7856; 128f: 32 / 64 / 17088;
  192s: 48 / 96 / 16224; 256s: 64 / 128 / 29792 bytes.
- **FIPS 204 errata note**: NIST's FIPS 204 publication page carries a
  planning note (31 July 2026) listing minor issues to be corrected in
  a future revision. None of the cited tables (sizes, categories) is
  affected by the errata note as published; the pack's size claims were
  additionally cross-checked against the implementation (see below).

## Implementation documentation

- **liboqs 0.16.0**, `docs/algorithms/sig/ml_dsa.yml` and
  `docs/algorithms/sig/slh_dsa.yml` (inside
  `fixtures/liboqs-0.16.0.tar.gz`, SHA256
  `162d5b510518ee5f285f82fa1f16402a885176e818bf1b1a4c3c91c9a2f01eae`) —
  algorithm identifiers used by the harness (`ML-DSA-44`, `ML-DSA-65`,
  `ML-DSA-87`, `SLH_DSA_PURE_SHA2_128S`, `SLH_DSA_PURE_SHA2_128F`,
  `SLH_DSA_PURE_SHA2_192S`, `SLH_DSA_PURE_SHA2_256S`), claimed NIST
  levels, and key/signature lengths. The yml sizes agree byte-for-byte
  with FIPS 204 Table 2 and FIPS 205 Table 2 for every parameter set
  used here, and the harness prints the lengths at runtime
  (`outputs/sign-tests.log`, `sizes:` lines).
- **liboqs 0.16.0 API**, `src/sig/sig.h` (same tarball) — the public
  `OQS_SIG_new` / `OQS_SIG_keypair` / `OQS_SIG_sign` /
  `OQS_SIG_verify` / `OQS_SIG_free` interface used by
  `src/release_sign.c`. No internal or private API is used.

## Transparency and related concepts

- **RFC 6962, *Certificate Transparency***, IETF, June 2013 —
  https://www.rfc-editor.org/rfc/rfc6962 — the append-only Merkle-tree
  log, inclusion-proof, and consistency concepts adapted (at small
  scale, for release records rather than certificates) by the demo in
  `src/tlog_demo.py`. The demo is a local, single-operator log, not a
  CT log: it has no external auditors, no gossip protocol, and no
  signed tree heads. Those limits are disclosed in
  `docs/methodology.md` (L5).
- **RFC 8259, *The JavaScript Object Notation (JSON) Data Interchange
  Format***, IETF, December 2017 — JSON data model used for the
  release manifest, rotation manifest, and transparency-log records.
  Records are canonicalized with sorted keys and no whitespace before
  signing (a deterministic subset of JSON canonicalization; see L4).

## Runtime documentation

- **Python 3.12.3 standard library documentation** — `hashlib`
  (SHA-256), `json`, `subprocess`, `tempfile` used by the demo and
  scripts. No third-party packages are used anywhere in this pack.
- **CMake 3.28.3 / GCC 13.3.0 documentation** — build tooling only;
  no specification-derived claim depends on them.
