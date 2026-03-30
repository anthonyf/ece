## Context

Two bugs in `wasm/runtime.wat` cause the WASM test suite to fail:

**Bug 1: `$fold-sub` first-operand type check missing.** `$fold-sub` extracts the first arg separately, then loops over remaining args. The `$all-int` flag only checks args in the loop, not the first arg. When the first arg is a float (e.g., `(- 3.5 3)`), `$all-int` stays 1, and the result is truncated via `$safe-trunc-i32`, losing the fractional part. `$fold-add` and `$fold-mul` don't have this bug because they iterate all args in the loop. `$fold-div` always returns float via `$wrap-f64`.

**Bug 2: `$wrap-f64` traps on large floats.** `$wrap-f64` calls `i32.trunc_f64_s` to check if a float is an integer that fits in fixnum range. But `i32.trunc_f64_s` is a WASM trapping instruction — it throws "float unrepresentable in integer range" if the value exceeds ±2^31. The range check comes *after* the trunc, so it never executes. This crashes during ECE tests that produce large intermediate values.

## Goals / Non-Goals

**Goals:**
- Fix `(- float fixnum)` to return float, not truncated integer
- Fix `$wrap-f64` to safely handle floats outside i32 range
- Enable strict WASM CI (remove `continue-on-error: true`)

**Non-Goals:**
- Refactoring all fold functions to a unified pattern
- Adding bignum or i64 support

## Decisions

### Decision 1: $fold-sub fix

**Choice**: Add a fixnum check for the first operand before the loop.

```wasm
;; Check first arg for float
(if (i32.eqz (call $is-fixnum (call $arg1 (local.get $args))))
  (then (local.set $all-int (i32.const 0))))
```

**Rationale**: Minimal, targeted fix. Matches the pattern used by `$fold-add` and `$fold-mul` where all args are checked.

### Decision 2: $wrap-f64 fix

**Choice**: Use `f64.ge`/`f64.le` range checks *before* calling `i32.trunc_f64_s`. Only trunc if the value is within i32 range.

```wasm
(if (f64.eq (local.get $n) (f64.trunc (local.get $n)))
  (then
    ;; Check i32 range BEFORE truncating
    (if (i32.and
          (f64.ge (local.get $n) (f64.const -2147483648))
          (f64.lt (local.get $n) (f64.const 2147483648)))
      (then
        (local.set $i (i32.trunc_f64_s (local.get $n)))
        ;; Check fixnum range
        ...))))
```

**Rationale**: Prevents the WASM trap by ensuring the value is in range before the trapping instruction executes. The fixnum range check (±536870911) is a subset of i32 range, so we can simplify to a single range check.

## Risks / Trade-offs

**[None] Behavioral change**: Both fixes correct incorrect behavior. No valid programs are affected — only buggy edge cases are fixed.

**[Low] Performance**: Adding a range check before trunc adds one f64 comparison. Negligible for the hot path.
