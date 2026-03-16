## Context

CI runs `qlot exec sbcl --eval '(asdf:test-system :ece)' --quit`. Rove's `rove:run` returns `NIL` on failure but never signals — ASDF's `test-op` discards the return value, and `--quit` always exits 0. Meanwhile, `test-error-context` has been failing since the compiler moved to vector-based environment frames, but CI never caught it.

## Goals / Non-Goals

**Goals:**
- CI exits non-zero when any test fails
- `test-error-context` passes with the current vector-frame environment representation

**Non-Goals:**
- Reconstructing variable names in error environments (that's a separate enhancement)
- Changing rove or ASDF behavior upstream

## Decisions

### CI: check rove's return value directly

Replace `(asdf:test-system :ece)` with two evals:

```bash
qlot exec sbcl --eval '(asdf:load-system :ece/tests)' \
               --eval '(unless (rove:run :ece/tests) (uiop:quit 1))' \
               --quit
```

**Why**: `asdf:test-system` swallows the result. Calling `rove:run` directly and branching on its boolean return is the simplest fix. `uiop:quit` is portable and available everywhere ASDF is.

**Alternative considered**: Wrapping `asdf:test-system` and checking `rove:*stats*` afterward — more fragile, depends on rove internals.

### Test: assert on vector frame values, not variable names

The compiler's `extend-environment` (4-arg path) creates `#(val1 val2 ...)` vectors — no variable names. The test should check:
1. Frame is a `simple-vector`
2. The value `5` is present at index 0

**Why**: Variable names are a compile-time concept; the runtime only needs indices. Changing the environment representation to include names would hurt performance for no runtime benefit.

## Risks / Trade-offs

- **[Risk]** Future rove versions could change `rove:run`'s return convention → **Mitigation**: This is rove's documented API; unlikely to change silently.
- **[Trade-off]** The test no longer verifies variable *names* in error environments, only values → Acceptable because the compiler doesn't store names in frames. A future "source location tracking" feature could restore name-level testing.
