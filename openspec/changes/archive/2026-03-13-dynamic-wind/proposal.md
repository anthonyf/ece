## Why

ECE has no way to intercept or inspect errors from ECE code. The current `try-eval` is a CL-side escape hatch that discards error details. The native test suite can only assert that errors occur, not what they say. Without `dynamic-wind`, there is no standard mechanism for resource cleanup or proper exception handler installation. This blocks error message testing, user-defined error handlers, and standard Scheme exception patterns (`guard`/`raise`).

## What Changes

- **Rename `call/cc` special form to `%raw-call/cc`** in both CL and self-hosted compilers. This is the only CL kernel change (~5 lines). The raw capture mechanism is preserved but given an internal name.
- **Add `dynamic-wind` in pure ECE** — manages a winding stack of `(before . after)` thunk pairs. Properly unwinds/rewinds when continuations cross dynamic extents.
- **Redefine `call/cc` as a macro** that expands to `%raw-call/cc` + winding-aware continuation wrapper. Zero overhead when no `dynamic-wind` is active. `call-with-current-continuation` provided as a first-class function alias.
- **Add error objects** via `define-record` — `error-object?`, `error-object-message`, `error-object-irritants`. The `error` primitive is redefined to construct error objects and raise them.
- **Add `raise` and `with-exception-handler`** — R7RS-style exception handling using `dynamic-wind` for proper handler installation/removal across continuation jumps.
- **Add `guard` macro** — R7RS cond-style exception handler. Evaluates clauses in the guard's continuation; re-raises if no clause matches.
- **Enhance test framework** with `assert-error-message` using `guard` to catch and inspect error objects.
- **Add test files** for dynamic-wind, guard/raise, and error messages.

## Capabilities

### New Capabilities
- `dynamic-wind`: R7RS `dynamic-wind` with winding stack management and `do-winds!` for continuation-crossing unwind/rewind
- `exception-handling`: `raise`, `with-exception-handler`, `guard` macro, error object records (`error-object?`, `error-object-message`, `error-object-irritants`)
- `error-message-tests`: Test suite for verifying error message content across type errors, arity errors, unbound variables, and custom errors

### Modified Capabilities
- `callcc-special-form`: Raw special form renamed to `%raw-call/cc`; `call/cc` becomes a macro wrapping it with winding support
- `error-signaling`: `error` redefined to construct error-object records and raise them via the exception system
- `ece-test-framework`: New `assert-error-message` macro for testing error message content

## Impact

- **CL kernel** (`src/compiler.lisp`): ~5 lines — rename `call/cc` → `%raw-call/cc` in `*special-forms*`, predicate, compile dispatch
- **Self-hosted compiler** (`src/compiler.scm`): Same rename in `*special-forms*` list, `mc-callcc?` predicate, and `mc-compile-callcc`
- **Prelude** (`src/prelude.scm`): ~90 lines new code — dynamic-wind, call/cc macro, error objects, raise, with-exception-handler, guard
- **Test framework** (`tests/ece/test-framework.scm`): ~10 lines — `assert-error-message` macro
- **New test files**: `test-dynamic-wind.scm`, `test-guard.scm`, `test-error-messages.scm` (~60-80 tests)
- **Existing code using `call/cc`**: The `loop` macro and `call/cc` tests continue to work — `call/cc` macro expands transparently. Existing `loop`/`break` patterns are unaffected.
