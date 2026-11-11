# Threat model — release signing with ML-DSA / SLH-DSA

## Scope

The system under assessment: a release pipeline that signs release
artifacts with ML-DSA or SLH-DSA (liboqs 0.16.0, optimized build) and
publishes signatures, a release manifest, and a transparency log.
Attackers considered: a network attacker who can substitute artifacts,
a compromised build host, a signer under fault injection, and a
malicious transparency-log operator. Out of scope: the security of the
liboqs implementations themselves (assumed correct as shipped;
validated here only through the functional test suite), and the
physical security of the signing host.

## Findings (severity-rated)

| ID | Severity | Finding | Mitigation / status |
| --- | --- | --- | --- |
| F1 | Informational | Signatures are randomized (hedged) per FIPS 204/205: the same key and artifact produce different valid signatures on each run. | Verifiers must never compare signature bytes; verify cryptographically. The harness and tests assert on verification outcomes only. |
| F2 | Low | Secret keys live as files in the work directory during a run. Anyone who can read the work directory can sign as the release key. | Accepted for this reference (ephemeral test keys, discarded with the work directory). Production: generate and hold keys in an HSM/KMS; see the runbook. |
| F3 | Low | SLH-DSA signing is slow (128s: 720 ms; 192s: 1,269 ms; 256s: 1,127 ms per signature). A signer that signs on demand is an easy slowdown target. | Rate-limit signing requests; sign releases in a batch job, not per-request. Measured in `outputs/benchmarks-run1.log`. |
| F4 | Informational | SLH-DSA signatures are large (7,856–29,792 B) and inflate manifests, logs, and distribution bandwidth. | Accepted: budget for it in the manifest format (see decision matrix). ML-DSA signatures are 2,420–4,627 B. |
| F5 | Low | Fault attacks on lattice signing are a known research area: a fault during ML-DSA signing can in principle leak secret-key material (published Dilithium fault-attack literature). No fault attack was attempted or tested here. | Production signers should use fault-resistant implementations or HSMs and verify each signature immediately after signing (the harness verifies round-trips in tests; a production signer should verify before publishing). |
| F6 | Informational | The two schemes rely on different hardness assumptions (lattices vs hash functions). A break in one family affects only that scheme's releases. | Diversification argument for using SLH-DSA for long-lived signatures; see the decision matrix. Not a mitigation by itself — a break still requires re-signing. |
| F7 | Low | The transparency-log demo is single-operator with no witnesses, gossip, or signed tree heads: a malicious operator could present split views (see `docs/tlog-design.md`). | Accepted for the demo. A production log needs independent monitors and signed tree heads (RFC 6962). |
| F8 | Low | Revocation is procedural only (methodology L9): the harness does not enforce a revocation list, so a verifier that ignores the revocation record would still cryptographically verify a revoked key's signatures. | Runbook procedure (publish + log the revocation); verifiers must check key status before verifying. Enforcement in code is future work. |

## What the test suite does and does not prove

Proven by `outputs/sign-tests.log` (8 checks × 7 parameter sets, all
PASS): round-trip verification works; tampered artifacts, tampered
signatures, and wrong keys are rejected. Proven by the demo logs:
inclusion proofs verify; tampering changes the log root; rotation
works and cross-key verification fails closed.

Not proven: resistance to fault injection (F5), side-channel leakage
(timing/power — the pure timing medians are performance numbers, not a
constant-time audit), or the correctness of liboqs beyond its public
API behaviour exercised here. The harness uses only the public
`OQS_SIG` API; no internal implementation detail is relied on.
