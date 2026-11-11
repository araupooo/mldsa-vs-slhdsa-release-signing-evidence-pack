#!/usr/bin/env python3
"""tlog_demo.py — append-only transparency log demo for release signatures.

Builds a small Merkle-tree transparency log (SHA-256) over signed release
records. Each record is signed with the release_sign harness (ML-DSA or
SLH-DSA) before it is appended; the leaf hash covers the canonical record
plus the signature bytes. The demo then:

  1. appends N signed release records and prints the Merkle root,
  2. produces and verifies an inclusion proof for one entry,
  3. tampers with a copy of the log (changes one entry's artifact hash)
     and shows the recomputed root no longer matches, and that the
     original inclusion proof fails against the tampered log.

Keys are generated at runtime in a temporary directory and never written
to the pack. Signatures are randomized (hedged) per FIPS 204/205, so leaf
hashes differ between runs; the demo asserts on outcomes (proof verifies,
tamper detected), never on fixed hash values.

Usage:
  python3 src/tlog_demo.py --harness <path/to/release_sign> \
      --alg ML-DSA-65 --artifact <release tarball> --workdir <dir> [--entries 5]

Exit code 0 iff the inclusion proof verifies and the tamper is detected.
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile


def canon(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()


def sha256(b):
    return hashlib.sha256(b).digest()


def merkle_root(leaves):
    """leaves: list of 32-byte hashes. Duplicate the last leaf if odd."""
    if not leaves:
        return sha256(b"")
    level = list(leaves)
    while len(level) > 1:
        nxt = []
        for i in range(0, len(level) - 1, 2):
            nxt.append(sha256(level[i] + level[i + 1]))
        if len(level) % 2 == 1:
            nxt.append(sha256(level[-1] + level[-1]))
        level = nxt
    return level[0]


def inclusion_proof(leaves, index):
    """Return list of (sibling_hash, sibling_is_left) from leaf to root."""
    proof = []
    level = list(leaves)
    idx = index
    while len(level) > 1:
        if idx % 2 == 0:
            sib = idx + 1
            if sib < len(level):
                proof.append((level[sib], False))
            else:
                proof.append((level[idx], False))  # duplicated last leaf
        else:
            proof.append((level[idx - 1], True))
        nxt = []
        for i in range(0, len(level) - 1, 2):
            nxt.append(sha256(level[i] + level[i + 1]))
        if len(level) % 2 == 1:
            nxt.append(sha256(level[-1] + level[-1]))
        level = nxt
        idx //= 2
    return proof


def verify_proof(leaf, proof, root):
    cur = leaf
    for sib, sib_is_left in proof:
        cur = sha256(sib + cur) if sib_is_left else sha256(cur + sib)
    return cur == root


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"tlog: command failed: {' '.join(cmd)}\n{r.stdout}{r.stderr}",
              file=sys.stderr)
        sys.exit(1)
    return r.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--harness", required=True)
    ap.add_argument("--alg", required=True)
    ap.add_argument("--artifact", required=True)
    ap.add_argument("--workdir", required=True)
    ap.add_argument("--entries", type=int, default=5)
    args = ap.parse_args()

    with open(args.artifact, "rb") as f:
        artifact_bytes = f.read()
    artifact_sha = hashlib.sha256(artifact_bytes).hexdigest()

    workdir = args.workdir
    os.makedirs(workdir, exist_ok=True)
    entries = []
    leaves = []
    for seq in range(args.entries):
        version = f"1.4.{seq}"
        key_id = f"release-2026-11-{args.alg.lower()}-v{seq + 1}"
        record = {
            "seq": seq,
            "version": version,
            "artifact": os.path.basename(args.artifact),
            "artifact_sha256": artifact_sha,
            "alg": args.alg,
            "key_id": key_id,
        }
        rec_path = os.path.join(workdir, f"record-{seq}.json")
        with open(rec_path, "wb") as f:
            f.write(canon(record))
        pk = os.path.join(workdir, f"pk-{seq}.bin")
        sk = os.path.join(workdir, f"sk-{seq}.bin")
        sig = os.path.join(workdir, f"sig-{seq}.bin")
        run([args.harness, "keygen", args.alg, pk, sk])
        run([args.harness, "sign", args.alg, sk, rec_path, sig])
        with open(sig, "rb") as f:
            sig_bytes = f.read()
        leaf = sha256(canon(record) + sig_bytes)
        entries.append(record)
        leaves.append(leaf)
        print(f"tlog: append seq={seq} version={version} key_id={key_id} "
              f"sig_len={len(sig_bytes)} leaf={leaf.hex()[:16]}...")

    root = merkle_root(leaves)
    print(f"tlog: entries={len(entries)} merkle_root={root.hex()}")
    print(f"tlog: root_prefix={root.hex()[:16]}")

    # Inclusion proof for entry 2 (or the last one if fewer entries).
    idx = 2 if len(entries) > 2 else len(entries) - 1
    proof = inclusion_proof(leaves, idx)
    ok = verify_proof(leaves[idx], proof, root)
    print(f"tlog: inclusion proof seq={idx} steps={len(proof)} verified={ok}")
    # Inclusion proof for the entry we are about to tamper (seq 3), kept
    # so we can show a stale proof fails after the tamper.
    tamper_idx = 3 if len(entries) > 3 else 0
    tamper_proof = inclusion_proof(leaves, tamper_idx)
    tamper_proof_ok = verify_proof(leaves[tamper_idx], tamper_proof, root)
    print(f"tlog: inclusion proof seq={tamper_idx} (pre-tamper) verified={tamper_proof_ok}")

    # Tamper test: change the artifact hash of entry 3 in a COPY of the log.
    # The leaf hash covers the canonical record plus the original
    # signature bytes, so any change to a logged record changes the root.
    tampered = [dict(e) for e in entries]
    tampered[3 if len(entries) > 3 else 0]["artifact_sha256"] = "00" * 32
    tampered_leaves = []
    for seq, e in enumerate(tampered):
        with open(os.path.join(workdir, f"sig-{seq}.bin"), "rb") as f:
            sig_bytes = f.read()
        tampered_leaves.append(sha256(canon(e) + sig_bytes))
    tampered_root = merkle_root(tampered_leaves)
    root_mismatch = tampered_root != root
    # The stale proof for the tampered entry, checked against the
    # tampered leaf and the original root, must FAIL: the leaf changed
    # but the proof and root did not.
    stale_proof_ok = verify_proof(tampered_leaves[tamper_idx], tamper_proof, root)
    print(f"tlog: tamper seq={tamper_idx} artifact_sha256 replaced -> "
          f"root_changed={root_mismatch} tampered_root_prefix={tampered_root.hex()[:16]}")
    print(f"tlog: stale proof for tampered entry against original root "
          f"verified={stale_proof_ok} (expected False)")

    passed = ok and tamper_proof_ok and root_mismatch and not stale_proof_ok
    print(f"tlog_summary: entries={len(entries)} proof_verified={int(ok)} "
          f"tamper_detected={int(root_mismatch)} stale_proof_rejected={int(not stale_proof_ok)}")
    print(f"RESULT: {'PASS' if passed else 'FAIL'} tlog entries={len(entries)}")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
