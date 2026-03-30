## Why

ECE's `guard`, `raise`, and `error` already work on WASM (verified by testing). But two gaps prevent the guard tests from running:

1. `%raw-error` (primitive 81) is a no-op on WASM — needed as the fatal-error fallback when no handler is installed
2. Division-by-zero errors from `quotient`/`modulo`/`remainder` come from WAT's `$fold-div` which throws a JS exception via `$signal-error-str`, bypassing ECE's error system entirely. `guard` can't catch JS exceptions.

## What Changes

- Implement `%raw-error` in WASM to call `$signal-error-str` (fatal error)
- Add zero-divisor checks to `quotient`, `modulo`, and `remainder` in `prelude.scm` — these call ECE's `error` function, making them catchable by `guard` on all platforms
- Remove the WAT-level zero check from `$fold-div` — let IEEE 754 handle raw `/` (returns inf/NaN, which is correct for the primitive; the ECE-level wrappers catch the user-facing case)
- Re-add `test-guard.scm` to WASM test list
- Move division-by-zero tests from `test-arithmetic.scm` to `test-guard.scm` (they test `guard` behavior, not arithmetic)
- Two-pass bootstrap (prelude change)

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `wasm-runtime-errors`: Implement `%raw-error` primitive on WASM

## Impact

- **src/prelude.scm**: Add zero checks to `quotient`, `modulo`, `remainder`
- **wasm/runtime.wat**: Implement primitive 81 (`%raw-error`), remove `$fold-div` zero check and `$err-div-zero`/`$signal-error-str`
- **Makefile**: Re-add `test-guard.scm` to WASM test list
- **tests/ece/test-arithmetic.scm**: Remove division-by-zero guard tests (moved to test-guard.scm)
- **tests/ece/test-guard.scm**: Add division-by-zero guard tests
- **bootstrap/**: Two-pass rebuild
