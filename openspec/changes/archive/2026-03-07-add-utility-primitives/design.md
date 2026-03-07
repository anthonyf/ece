## Context

ECE currently lacks several small utility primitives needed for interactive fiction authoring: dramatic pacing (`sleep`), terminal clearing (`clear-screen`), input normalization (`string-downcase`, `string-upcase`), and multi-word input parsing (`string-split`). All five are thin wrappers around existing CL functionality or simple implementations.

## Goals / Non-Goals

**Goals:**
- Add `sleep`, `clear-screen`, `string-downcase`, `string-upcase`, `string-split` as wrapper primitives.
- Follow the existing `*wrapper-primitives*` pattern established by the DRY refactor.

**Non-Goals:**
- No regex or advanced string processing.
- No locale-aware case conversion.

## Decisions

### Decision 1: All primitives as wrapper functions in `*wrapper-primitives*`
Each primitive gets a CL wrapper function registered in `*wrapper-primitives*`. This follows the established pattern and keeps registration declarative.

### Decision 2: `string-split` uses a character delimiter
`string-split` takes a string and a character delimiter. This is sufficient for parsing space-separated input (`(string-split input #\Space)`) and avoids the complexity of regex-based splitting. If no delimiter is provided, default to `#\Space`.

### Decision 3: `clear-screen` uses ANSI escape codes
Output `ESC[2J` (clear screen) followed by `ESC[H` (cursor home) via `format`. This works on all modern terminals. Returns nil.

### Decision 4: `sleep` delegates directly to `cl:sleep`
Accepts a number (integer or float) and calls `cl:sleep`. Returns nil.

## Risks / Trade-offs

- `clear-screen` assumes ANSI terminal support. Non-ANSI terminals will see garbage characters. This is acceptable for an IF engine targeting modern terminals.
