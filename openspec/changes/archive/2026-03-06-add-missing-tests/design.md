## Context

The ECE project is an explicit control evaluator for a small Lisp. The evaluator in `src/main.lisp` supports self-evaluating expressions, variables, `quote`, `lambda`, `begin`, and primitive procedure application. The test file `tests/main.lisp` uses rove and only covers self-eval (numbers), variables, quote, and basic lambda application. Several implemented features have zero test coverage.

## Goals / Non-Goals

**Goals:**
- Achieve test coverage for all implemented and working evaluator features
- Validate primitive procedures exposed through `*global-env*`
- Test `begin` sequencing behavior
- Test string self-evaluation
- Test multi-body lambdas and nested applications
- Test error signaling for invalid inputs

**Non-Goals:**
- Testing unimplemented features (`if`, `set`, `call/cc` — these are stubbed but not functional)
- Refactoring the evaluator or test infrastructure
- Adding new evaluator features

## Decisions

**All tests in a single file**: Keep new tests in `tests/main.lisp` alongside existing tests. The project is small and rove runs the entire test system at once. No need for multiple test files.

**Use rove idioms consistently**: All assertions use `(ok (= ...))` for numeric comparisons, `(ok (equal ...))` for structural comparisons, and `(signals ...)` for error cases — matching the patterns already established.

**Test primitives via `evaluate` not directly**: Tests call `(evaluate '(+ 1 2))` rather than testing CL functions directly, since the goal is to verify the evaluator dispatch and application machinery.

## Risks / Trade-offs

- [Some primitives may behave differently in the evaluator context than in raw CL] → Each test verifies through `evaluate` to catch dispatch issues
- [Adding many tests increases test runtime] → Negligible for this project size
