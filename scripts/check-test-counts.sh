#!/bin/bash
# Compare actual test counts against baselines in tests/test-counts.json.
# Usage: check-test-counts.sh <suite-name> <actual-count>
# Exit 1 if actual count is below baseline.

set -e

SUITE="$1"
ACTUAL="$2"
BASELINES="tests/test-counts.json"

if [ ! -f "$BASELINES" ]; then
  echo "ERROR: $BASELINES not found"
  exit 1
fi

EXPECTED=$(python3 -c "import json; print(json.load(open('$BASELINES')).get('$SUITE', 0))")

if [ "$ACTUAL" -lt "$EXPECTED" ]; then
  echo "FAIL: $SUITE count dropped: expected >= $EXPECTED, got $ACTUAL"
  exit 1
else
  echo "OK: $SUITE count $ACTUAL >= baseline $EXPECTED"
fi
