## Context

The REPL exercises the full ECE pipeline (reader → compiler → assembler → executor → printer) but had zero test coverage. A crash bug involving circular references during printing was discovered manually. Integration tests need to drive the REPL with controlled input and verify output.

## Goals / Non-Goals

**Goals:**
- Test the REPL end-to-end with string-based I/O
- Cover: expressions, definitions, errors, edge cases, EOF handling
- Catch regressions like the circular-print crash

**Non-Goals:**
- Testing individual reader/compiler components (already covered by existing tests)
- Interactive/terminal-specific behavior (cursor, line editing)
- Performance benchmarking

## Decisions

### 1. Test via CL-level I/O redirection

Redirect `ece::*current-input-port*` to a string port and capture `*standard-output*` with `with-output-to-string`. This works because all ECE output primitives (`display`, `write`, `newline`) and `try-eval` error printing flow through CL's `*standard-output*`.

**Alternative considered:** Running the REPL as a subprocess with piped stdin/stdout. Rejected — too heavy, slower, harder to debug failures.

### 2. Single `run-repl` helper function

A helper `(run-repl input-string)` → output-string encapsulates the I/O redirection and calls `ece:repl`. Each test case is a simple string-in/string-out assertion.

### 3. Use `search` for output assertions

Match substrings in the captured output rather than exact string comparison. The REPL output includes prompts (`ece> `), newlines, and potentially varying whitespace. Substring matching is more robust and readable.

## Risks / Trade-offs

- [Global state] The REPL modifies `*global-env*` via `define`. Definitions from earlier test cases persist into later ones. → Acceptable since tests run in a known order and we can use unique names per test.
- [Output format coupling] Tests depend on exact REPL output format (prompt string, error prefix). → These are stable conventions unlikely to change without deliberate redesign.
