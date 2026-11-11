#!/usr/bin/env python3
"""make_manifest.py — write outputs/run-manifest.md.

Lists every file under outputs/ with its SHA256, plus the headline
results extracted from the shipped logs (test RESULT lines, bench lines,
demo RESULT lines). Run from anywhere; resolves the pack root.
"""
import hashlib
import os
import re
import sys

PACK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(PACK, "outputs")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def grep_lines(path, pattern):
    out = []
    try:
        with open(path, errors="replace") as f:
            for line in f:
                if re.search(pattern, line):
                    out.append(line.rstrip("\n"))
    except FileNotFoundError:
        pass
    return out


def main():
    import datetime
    files = []
    for root, _dirs, names in os.walk(OUT):
        for n in sorted(names):
            if n == "run-manifest.md":
                continue
            p = os.path.join(root, n)
            files.append(os.path.relpath(p, OUT))
    files.sort()
    lines = ["# Run manifest", "",
             f"Generated: {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}",
             "",
             "Commands: scripts/run_tests.sh, scripts/run_benchmarks.sh run1/run2, "
             "scripts/run_demo.sh (transparency log + key rotation), "
             "scripts/clean_reproduce.sh (fresh copy: full tests + full benchmarks + demos).",
             "",
             "## Output files (sha256)", ""]
    for rel in files:
        lines.append(f"{sha256(os.path.join(OUT, rel))}  {rel}")
    lines += ["", "## Headline results (from logs)", ""]
    for name, pat in (
        ("sign-tests.log", r"^(test_summary|RESULT):"),
        ("benchmarks-run1.log", r"^bench:"),
        ("benchmarks-run2.log", r"^bench:"),
        ("tlog-demo.log", r"^(tlog_summary|RESULT):"),
        ("rotation-demo.log", r"^RESULT:"),
    ):
        hits = grep_lines(os.path.join(OUT, name), pat)
        if hits:
            lines.append(f"### {name}")
            lines.extend(hits)
    with open(os.path.join(OUT, "run-manifest.md"), "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote outputs/run-manifest.md ({len(files)} files)")


if __name__ == "__main__":
    main()
