## Context

The evaluator uses an explicit control machine with a continuation stack (`conts`) and a data stack (`stack`). All registers (`expr`, `env`, `val`, `unev`, `argl`, `proc`) are local variables in the `evaluate` function. The machine state at any point is fully determined by `stack` + `conts` (plus the registers, but registers in flight are saved/restored via stack by calling continuations). This makes capturing continuations straightforward: snapshot `stack` and `conts`.

A stubbed `:ev-callcc` handler already exists with pseudocode comments.

## Goals / Non-Goals

**Goals:**
- Implement `(call/cc <receiver>)` where receiver is a one-argument procedure
- The receiver gets called with the current continuation as its argument
- Calling the continuation with a value V causes `call/cc` to "return" V
- Continuations are callable multiple times (multi-shot)
- Support both escaping (non-local exit) and re-entering uses

**Non-Goals:**
- Dynamic-wind / unwind-protect integration
- Delimited continuations (shift/reset)
- Optimizing continuation capture (copying is fine)

## Decisions

**Continuation representation**: `(continuation <saved-stack> <saved-conts>)` — a tagged list, matching the pattern of `(primitive <fn>)` and `(procedure params body env)`. Recognized by `:apply-dispatch`.

**Two-phase call/cc**: Since the receiver is an arbitrary expression that must be evaluated:
1. `:ev-callcc` — captures the continuation (copies stack + conts), pushes it onto stack, then dispatches to evaluate the receiver expression
2. `:ev-callcc-apply` — pops the captured continuation, sets proc=receiver (from val), argl=(continuation), goes to apply-dispatch

**Capturing registers**: Only `stack` and `conts` need to be captured. At the point `:ev-callcc` fires, all in-flight state from the calling context has already been saved to `stack` by the application/sequence machinery. The `conts` list holds what would happen next.

**Restoring continuations**: `:continuation-apply` in apply-dispatch copies the saved stack/conts back into the live registers and sets `val` to the argument. Copies on both capture and restore to support multi-shot continuations without aliasing.

**`call/cc` as a special form**: Added to `*special-forms*` so it's not treated as an application. The symbol is `call/cc` which is valid in CL.

## Risks / Trade-offs

- [Stack copying on every capture] → Acceptable for correctness; optimization is a non-goal
- [Multi-shot continuations may behave unexpectedly with mutation] → Standard Scheme semantics; document in tests
- [call/cc symbol contains `/`] → Valid CL symbol, but needs to be in the `ece` package; tests must use `ece::call/cc` since it won't be interned in test package automatically
