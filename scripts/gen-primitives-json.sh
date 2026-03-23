#!/bin/bash
# Generate wasm/primitives.json from primitives.def
# Includes only core and browser platform primitives (excludes cl-only).
# Output: JSON array of [id, "name"] pairs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DEF_FILE="$ROOT_DIR/primitives.def"
OUT_FILE="$ROOT_DIR/wasm/primitives.json"

if [ ! -f "$DEF_FILE" ]; then
  echo "Error: primitives.def not found at $DEF_FILE" >&2
  exit 1
fi

# Parse primitives.def: extract (id name arity platform desc) lines
# Filter to core and browser platforms only
awk '
BEGIN { first = 1; print "[" }
/^\(/ {
  # Remove parens and quotes
  gsub(/[()]/, "")
  id = $1
  name = $2
  platform = $4
  if (platform == "core" || platform == "browser") {
    if (!first) printf ",\n"
    printf "  [%d, \"%s\"]", id, name
    first = 0
  }
}
END { printf "\n]\n" }
' "$DEF_FILE" > "$OUT_FILE"

echo "Generated $OUT_FILE"
