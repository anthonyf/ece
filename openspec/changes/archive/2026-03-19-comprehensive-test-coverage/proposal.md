## Why

A test coverage audit revealed significant gaps: cross-space execution (the core new architecture) has no dedicated tests, mutation primitives are untested, file I/O is untested, multiple continuation invocation isn't verified, and several features only have CL-side tests with no ECE native equivalents. Any of these could silently break during refactoring.

## What Changes

- **Test-only change** — no production code modifications
- Add ECE native tests for all identified gaps across 17 areas
- New test files for areas not currently covered (cross-space, file I/O, mutation, advanced continuations)
- ECE native equivalents for features that only have CL-side tests (bitwise, random, write-to-string, named let, loop/collect)

## Capabilities

### New Capabilities
- `test-coverage`: Comprehensive ECE native test coverage for cross-space execution, mutation, file I/O, advanced continuations, and all lightly-tested features.

### Modified Capabilities
(none — test-only change)

## Impact

- **`tests/ece/`**: New test files for cross-space, mutation, file I/O, advanced continuations, and ECE-native versions of CL-only tests
- **`tests/ece/run-all.scm`**: Add new test file loads
- No changes to `src/`, `bootstrap/`, `primitives.def`, or `Makefile`
