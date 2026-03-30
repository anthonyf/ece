## Context

Investigation confirmed that ECE's `guard`/`raise`/`error`/`with-exception-handler` chain works correctly on WASM — all are ECE-level code using `*current-exception-handler*` and `call/cc`. The only gap is when errors originate from WAT operations (JS exceptions bypass ECE entirely).

The ECE error chain: `guard` installs handler → body calls `error` → `error` calls `raise` → `raise` invokes `*current-exception-handler*` → handler runs → `guard` continuation returns result.

The fallback chain: `raise` with no handler → calls `%raw-error` (primitive 81) → should be fatal.

## Goals / Non-Goals

**Goals:**
- Make `guard` catch division-by-zero errors on WASM
- Implement `%raw-error` as fatal error on WASM
- Re-enable guard tests on WASM
- Keep raw `/` primitive returning IEEE 754 values (inf/NaN) on WASM

**Non-Goals:**
- Making WAT-level traps (illegal cast, stack overflow) catchable by `guard`
- Implementing `try-eval` on WASM (separate concern)
- Fixing the `define-syntax` illegal cast issue (separate bug)

## Decisions

### Decision 1: Zero checks in ECE prelude, not WAT

**Choice**: Add `(if (= b 0) (error "/: division by zero") ...)` to `quotient`, `modulo`, and `remainder` in `prelude.scm`. Remove the WAT-level zero check from `$fold-div`.

**Rationale**: ECE-level `error` calls `raise` which goes through the handler chain. `guard` can catch it. WAT-level `$signal-error-str` throws a JS exception which bypasses ECE entirely. Moving the check to ECE makes it work uniformly on both CL and WASM.

Raw `/` stays IEEE 754 on WASM (`(/ 10 0)` → inf) because the Scheme standard allows implementation-defined behavior for raw division by zero, and the user-facing operations (`quotient`/`modulo`/`remainder`) are what need the error.

### Decision 2: %raw-error implementation

**Choice**: Dispatch primitive 81 in WASM to call `$signal-error-str` with the first argument converted to a string.

**Rationale**: `%raw-error` is the fatal-error fallback — it should terminate execution. On CL it maps to `(error ...)`. On WASM, `$signal-error-str` writes to linear memory and calls `$js-runtime-error` which throws a JS exception. This matches the intent: unrecoverable error.

### Decision 3: Remove $signal-error-str and $err-div-zero from $fold-div

**Choice**: Revert the `$fold-div` zero check added in PR #76. Also remove the `$err-div-zero` global string and `$signal-error-str` helper (no longer needed — `%raw-error` handles fatal errors).

**Rationale**: `$signal-error-str` was added specifically for division-by-zero. With the check moved to ECE prelude, there's no WAT code that needs string-based error signaling. The `$signal-error-sym` function remains (used for "Unbound variable" errors).

Wait — actually `$signal-error-str` is useful for `%raw-error` implementation. Keep it.

**Revised**: Keep `$signal-error-str`. Remove only the `$fold-div` zero check and `$err-div-zero` constant.

## Risks / Trade-offs

**[Low] Raw `/` behavior divergence**: On CL, `(/ 10 0)` signals an error. On WASM, it returns `+inf.0`. This only matters if code uses raw `/` with zero divisor without going through `quotient`/`modulo`. This is acceptable — Scheme allows implementation-defined behavior here, and the user-facing operations are protected.

**[None] Guard behavior**: `guard` already works on WASM. This change just enables the tests and fixes the error source.
