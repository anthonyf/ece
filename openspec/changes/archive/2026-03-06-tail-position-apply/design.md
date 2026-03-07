## Context

The `ev-apply-dispatch` handler already restores the caller's saved conts and env from the data stack before pushing to `apply-dispatch`. This means `apply` in tail position does not grow the stack. Empirically verified with 1M iterations.

## Goals / Non-Goals

**Goals:**
- Add regression test for tail-position apply

**Non-Goals:**
- Changing the evaluator (it already works)

## Decisions

### Decision: Add to existing test-tail-call-optimization deftest
One additional `testing` clause, consistent with the other TCO tests.

## Risks / Trade-offs

None — purely additive test.
