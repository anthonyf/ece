## Why

All 689 test assertions currently run in Common Lisp using rove. When ECE is ported to other platforms (C, WebAssembly), these CL tests cannot verify the new runtime. Roughly 74% of assertions (~420) test pure ECE language semantics — they're just `(evaluate '(expr)) => value` — and could be written as `.scm` files runnable on any ECE platform. A shared, platform-independent test suite ensures correctness across all runtimes.

## What Changes

- Add a minimal ECE-native test framework (a few functions: `test`, `assert-equal`, `run-tests`, test runner with pass/fail counting)
- Create `.scm` test files covering Tier 1 (pure ECE semantics) tests: arithmetic, lists, strings, vectors, hash tables, closures, macros, TCO, call/cc, higher-order functions, etc.
- Add a `make test-ece` target that loads the image and runs the ECE test suite
- The existing CL/rove test suite stays — it continues to cover host integration (image save/load, REPL, ports) and serves as the regression suite for the CL runtime

## Capabilities

### New Capabilities
- `ece-test-framework`: Minimal test runner written in ECE — defines `test`, `assert-equal`, `assert-true`, result reporting with pass/fail counts
- `ece-test-suite`: Collection of `.scm` test files covering pure ECE language semantics (arithmetic, data structures, control flow, macros, closures, TCO, etc.)

### Modified Capabilities

## Impact

- New files: `src/test-framework.scm`, `tests/*.scm` (multiple test files by category), Makefile target
- No changes to existing code — additive only
- The ECE test suite becomes the portable correctness contract for any future runtime
