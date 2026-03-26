## Why

`call/cc` continuations can be serialized and loaded, but invoking a loaded continuation crashes. Raw continuations (`%raw-call/cc`) work end-to-end. The issue: `call/cc` wraps the raw continuation in a lambda for `dynamic-wind` support (`do-winds!`). When the wrapper invokes the raw continuation, the executor replaces the local stack with the continuation's saved stack, losing saves from the wrapper's own execution.

This is NOT a serialization bug — it's structural. SICP's `call/cc` has no wrapper (no `dynamic-wind`). The wrapper was added for R7RS compliance. When there are no active dynamic-winds (`*winding-stack*` is empty), the wrapper is a pure no-op — `do-winds!` with equal empty stacks does nothing.

## What Changes

- Optimize `call/cc` macro: when `*winding-stack*` is empty (no active dynamic-winds), delegate directly to `%raw-call/cc` — no wrapper lambda. This is the SICP behavior.
- When dynamic-winds ARE active, keep the existing wrapper for R7RS `do-winds!` support.
- This makes `call/cc` continuations serializable and invokable in the common case (no dynamic-winds), which covers the IF game save/load use case.

## Capabilities

### New Capabilities
_None_

### Modified Capabilities
- `callcc-special-form`: Skip `do-winds!` wrapper when no dynamic-winds are active

## Impact

- `src/prelude.scm` — `call/cc` macro (~3 lines changed)
- `bootstrap/*.ecec` — regenerated
- `tests/ece/test-roundtrip.scm` — upgrade raw continuation test to use `call/cc`
