## Context

ECE has 438 tests (236 ECE native + ~116 CL deftests with multiple assertions). A coverage audit found 17 areas that are untested or only tested from the CL side. This change adds ECE native tests for all gaps.

## Goals / Non-Goals

**Goals:**
- Every user-facing feature has at least one ECE native test
- Edge cases for core semantics (continuations, parameters, cross-space) tested
- No production code changes

**Non-Goals:**
- Performance benchmarks
- Stress testing / fuzzing
- 100% line coverage (focus on behavioral coverage)

## Decisions

### 1. New test files for new areas

**Choice:** Create new test files rather than adding to existing ones:
- `test-cross-space.scm` — cross-space execution
- `test-mutation.scm` — set-car!, set-cdr!
- `test-file-io.scm` — file I/O primitives
- `test-advanced-continuations.scm` — multi-invoke, parameterize interaction
- `test-misc.scm` — bitwise, random, write-to-string, keyword?, platform-has?, named let, loop/collect, macro shadowing

**Why:** Keeps test organization clear. Each file covers a distinct concern.

### 2. All tests use the existing test framework

**Choice:** Use the ECE test framework (`test`, `assert`, `assert-equal`) from `test-framework.scm`. No new test infrastructure.

### 3. Temp files for I/O tests

**Choice:** File I/O tests create temp files in `/tmp/ece-test-*` and clean up after themselves.
