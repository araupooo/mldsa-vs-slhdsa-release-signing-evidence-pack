#!/bin/bash
# test_all.sh — entry point for the signature correctness suite.
# Runs the full test suite (8 checks x 7 parameter sets) via
# scripts/run_tests.sh; the checks themselves live in
# src/release_sign.c ("test" subcommand). Unedited output goes to
# outputs/sign-tests.log. Exit code 0 iff every check passes.
# Usage: bash tests/test_all.sh
set -u
PACK="$(cd "$(dirname "$0")/.." && pwd)"
bash "$PACK/scripts/run_tests.sh"
