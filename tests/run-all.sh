#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

run_test() {
  local name="$1"
  local cmd="$2"
  echo ""
  echo "=== $name ==="
  if bash -c "$cmd"; then
    echo "PASS: $name"
    PASS=$((PASS+1))
  else
    echo "FAIL: $name"
    FAIL=$((FAIL+1))
  fi
}

run_test "sniff-test: detects AI tells" \
  "bash '$TESTS_DIR/sniff-test.sh' '$TESTS_DIR/fixtures/bad-prototype' && exit 1 || exit 0"

run_test "sniff-test: passes clean prototype" \
  "bash '$TESTS_DIR/sniff-test.sh' '$TESTS_DIR/fixtures/good-prototype'"

run_test "reference-validator: rejects adjectives" \
  "bash '$TESTS_DIR/reference-validator.sh' 'modern, clean' && exit 1 || exit 0"

run_test "reference-validator: accepts URLs and brands" \
  "bash '$TESTS_DIR/reference-validator.sh' 'https://stripe.com, Bauhaus, Bloomberg, 90s magazine'"

run_test "template-rendering: no unsubstituted placeholders" \
  "bash '$TESTS_DIR/template-rendering.sh' \
     '$TESTS_DIR/fixtures/sample-brief.md' \
     '$TESTS_DIR/tmp-output'"

echo ""
echo "=========================="
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
