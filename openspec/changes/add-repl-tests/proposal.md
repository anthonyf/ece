## Why

The REPL had no integration tests. A crash bug (infinite recursion when printing compiled procedures with circular environment references) was found and fixed but could easily regress. The REPL is a critical user-facing component that exercises the full pipeline: ECE reader → compiler → assembler → executor → printer.

## What Changes

- Add a `run-repl` test helper that feeds string input to the REPL and captures output
- Add a `test-repl` deftest covering: simple expressions, arithmetic, multi-expression sessions, variable/function definition, error recovery, string/boolean output, lambda printing, and EOF/goodbye

## Capabilities

### New Capabilities
- `repl-tests`: Integration tests for the ECE REPL covering read-eval-print loop scenarios

### Modified Capabilities

## Impact

- `tests/ece.lisp` — new deftest and helper function added
