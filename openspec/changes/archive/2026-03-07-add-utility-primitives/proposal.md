## Why

The remaining Priority 2 roadmap items — `sleep`, `clear-screen`, `string-downcase`, and `string-split` — are small utility primitives that improve the IF authoring experience. Dramatic pacing, clean room transitions, and input normalization are basic needs for any interactive fiction game.

## What Changes

- **`sleep`**: Pause execution for a given number of seconds (supports fractional). Wraps CL's `cl:sleep`.
- **`clear-screen`**: Clear the terminal using ANSI escape sequence `ESC[2J ESC[H`. Returns nil.
- **`string-downcase`**: Convert a string to lowercase. Wraps CL's `string-downcase`.
- **`string-upcase`**: Convert a string to uppercase. Wraps CL's `string-upcase`.
- **`string-split`**: Split a string by a delimiter character, returning a list of substrings.

## Capabilities

### New Capabilities
- `timing-primitives`: `sleep` for dramatic pacing.
- `terminal-control`: `clear-screen` for room transitions.
- `string-case-ops`: `string-downcase` and `string-upcase` for input normalization.
- `string-split-op`: `string-split` for parsing multi-word input.

### Modified Capabilities

## Impact

- `src/main.lisp` — New wrapper functions, new entries in `*wrapper-primitives*`, new package exports.
- `tests/main.lisp` — New tests for each primitive.
