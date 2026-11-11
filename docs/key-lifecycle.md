# Key-lifecycle runbook — ML-DSA / SLH-DSA release signing

## Key identifiers

Every release-signing key carries a key identifier of the form
`release-<YYYY-MM>-<alg-lower>-v<N>` (e.g.
`release-2026-11-mldsa65-v1`). The identifier is recorded in the
release manifest next to the artifact name, version, artifact SHA256,
algorithm name, and signature file. The identifier is the only thing a
verifier needs to select the right public key: verification is
`release_sign verify <alg> <pkfile> <artifact> <sigfile>` with the
public key fetched by key id. Public-key prefixes (first 16 bytes,
hex) are published in `outputs/rotation-manifest.json` so a verifier
can confirm it holds the intended key before verifying.

Key material itself is never committed to the repository and never
appears in any log. Test keys in this pack are generated at runtime by
`release_sign keygen` (liboqs' own randomness) into a work directory
and discarded with it.

## Generation

1. Choose the parameter set from the decision matrix
   (`docs/decision-matrix.md`). Default for general releases:
   ML-DSA-65 (category 3, 3,309-byte signatures).
2. Generate on a clean machine: `release_sign keygen ML-DSA-65 pk.bin sk.bin`.
3. Record the public-key SHA256 and the key id in the release manifest.
   Store the secret key offline (encrypted at rest; see "Hardware-backed
   options" below). The harness prints only the public-key prefix.
4. Verify the keypair before first use: sign a canary artifact and
   verify it (`scripts/run_tests.sh` does this for every parameter set;
   see `outputs/sign-tests.log`).

## Rotation

Rotation is demonstrated end-to-end in `outputs/rotation-demo.log`
(and `scripts/run_demo.sh`):

1. Generate the new key (`v2`) while the old key (`v1`) is still active.
2. Sign the next release with `v2`; publish the new public key and key
   id in the release manifest.
3. Old releases keep verifying under the retired `v1` key — the demo
   proves this (`v1 signature verifies with retired v1 key: OK`).
4. A signature made with `v1` does NOT verify under `v2`
   (`wrong_key_rejected`, demonstrated in the demo and in the test
   suite) — so a verifier that has the wrong key fails closed instead
   of silently accepting.
5. Mark `v1` `retired` in the manifest; keep its public key published
   for as long as any release signed by it must remain verifiable.

Rotate on a schedule (at most every 12 months for the active release
key) and immediately on any suspicion of compromise (see below).
ML-DSA key generation is fast (measured in `outputs/benchmarks-*.log`),
so rotation cost is dominated by distribution, not cryptography.
SLH-DSA key generation is also fast (a keypair is a 32/48/64-byte seed
expansion); the cost of SLH-DSA rotation is the signature size, not
key generation.

## Revocation

- Publish a revocation record for the key id in the release manifest
  channel (and, when the transparency log is in use, append a
  revocation entry to the log — see `docs/tlog-design.md`).
- Verifiers must refuse signatures under a revoked key id even if the
  cryptography verifies: key-id checking happens before signature
  verification in the release workflow. This pack's harness does not
  implement a revocation list — the runbook step is procedural, and
  that gap is disclosed as a limitation (L9).
- Keep the revoked public key published (marked revoked) so that the
  revocation itself is auditable.

## Compromise response

1. **Contain:** stop signing with the compromised key immediately;
   generate a replacement key and sign the next release with it.
2. **Assess:** list every release signed with the compromised key
   (the transparency log gives the complete list — each entry records
   its key id). Re-sign and re-publish any release that must remain
   trustworthy; the old signatures stay verifiable under the retired
   key, so re-signing is a policy decision per release, not a
   cryptographic emergency for already-published artifacts whose
   contents are unchanged.
3. **Revoke:** publish the revocation record (above) and append it to
   the transparency log.
4. **Rotate dependents:** any system that pinned the compromised
   public key must fetch the replacement (same distribution channel as
   the release manifest).
5. **Review:** ML-DSA and SLH-DSA have no known key-recovery attack
   from signatures alone; compromise means the secret key bytes were
   exposed (host breach, bad storage), not a cryptanalytic break.
   Treat it as an operational incident, not an algorithm incident —
   unless the compromise came from a fault attack on signing, in
   which case see the fault-attack note in the threat model
   (`docs/threat-model.md`, F5).

## Hardware-backed signing options

**Status: not tested here.** No HSM or secure enclave was available on
the build machine (see methodology L6). The options below are
documented from vendor and standards sources only; none was exercised
by the harness, and no performance or security claim is made for them.

- **PKCS#11 HSMs** (e.g. network HSMs with post-quantum firmware):
  ML-DSA is the scheme HSM vendors are adding first, because its
  signing is fast and its keys fit HSM key objects. SLH-DSA's large
  signatures are a storage concern on constrained HSMs. Key generation
  and signing happen inside the module; the secret key never leaves it.
  Rotation = generate a new key object, publish the new public key.
- **Cloud KMS with PQC support:** same model as PKCS#11, with the
  provider operating the module. Check that the provider's ML-DSA /
  SLH-DSA support is generally available (not preview) before relying
  on it, and confirm which parameter sets are offered.
- **TPM 2.0:** current TPMs do not generally offer ML-DSA/SLH-DSA
  signing; do not plan a TPM-based release-signing flow until the
  vendor documents it.
- **Smart cards / USB tokens:** as with TPMs, post-quantum support is
  vendor-specific and usually absent; verify before planning.
- **Threshold / multi-party signing:** not covered here. If a single
  signing key is an unacceptable concentration of risk, a threshold
  ML-DSA scheme is future work — do not improvise one.

## What this runbook does not cover

- Long-term archival verification (decades): ML-DSA/SLH-DSA are
  designed for long-term security, but this pack does not test
  verification after simulated algorithm deprecation. Plan a
  re-signing migration if NIST ever deprecates a parameter set.
- Revocation-list enforcement in the harness (procedural only, L9).
- Multi-signature release policies (e.g. two signers per release):
  the harness signs with one key per release; the manifest format
  supports listing multiple signatures but the workflow does not
  demonstrate it.
