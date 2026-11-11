# Transparency-log design (demo)

## What it is

A minimal append-only transparency log for release signatures,
implemented in `src/tlog_demo.py` (Python 3 standard library only).
Each log entry is a signed release record:

```json
{"seq": 2, "version": "1.4.2", "artifact": "release-1.4.2.tar.gz",
 "artifact_sha256": "<hex>", "alg": "ML-DSA-65",
 "key_id": "release-2026-11-ml-dsa-65-v3"}
```

The record is canonicalized (sorted keys, no whitespace) and signed
with the release-signing harness before appending. The leaf hash is
`SHA256(canonical_record || signature_bytes)`; leaves are combined
into a binary Merkle tree (SHA-256, last leaf duplicated when a level
is odd). The demo appends 5 entries, prints the Merkle root, verifies
an inclusion proof for one entry, then tampers with a copy of the log
and shows (a) the recomputed root changes and (b) the original
inclusion proof for the tampered entry no longer verifies against the
original root.

Run it with `scripts/run_demo.sh`; unedited output is in
`outputs/tlog-demo.log`.

## Concepts borrowed from RFC 6962

- **Append-only log + Merkle tree**: entries are only appended;
  the root commits to the full history (RFC 6962 §2, §3).
- **Inclusion proof**: a list of sibling hashes from leaf to root
  (RFC 6962 §2.1.1). A verifier holding only the root can confirm an
  entry is in the log without downloading it.
- **Tamper evidence**: any change to a logged entry changes the root,
  and a proof computed before the change fails afterwards.

## What it is NOT (disclosed limits)

- **Single operator, no witnesses.** A real transparency log
  (RFC 6962) relies on independent monitors, auditors, and gossip to
  detect a malicious log operator presenting split views. This demo
  has one operator and no gossip: it demonstrates the data structure,
  not the trust model. A malicious operator of this demo log could
  maintain two different logs with two different roots.
- **No signed tree heads.** RFC 6962 logs sign tree heads; this demo
  prints the root but does not sign it. A verifier therefore cannot
  distinguish a root the operator computed from one it invented.
- **No consistency proofs.** The demo does not implement
  consistency proofs between successive roots (RFC 6962 §2.1.2);
  append-only behaviour is asserted by construction, not proven.
- **In-memory only.** The log is rebuilt from scratch on each run;
  there is no persistent store, no replication, and no availability
  story.
- **Record canonicalization is a subset** (sorted JSON keys, no
  whitespace), not full JCS (RFC 8785) — see methodology L4.

## How it would grow into a real log

Add signed tree heads (signed with the release key), a persistent
append-only store, consistency proofs, independent mirrors, and a
monitor that fetches every new root and checks that previously seen
entries are still included. None of that is implemented here; the
demo's job is to show the core mechanics run end-to-end on real
signatures.
