## Context

ECE has `error` as a primitive (mapped to CL's `error`). There is no structured error handling — errors propagate to CL. `assert` is a simple convenience macro over `error`.

## Goals / Non-Goals

**Goals:**
- Add `assert` macro to the prelude
- Support optional error message

**Non-Goals:**
- Structured error handling (`guard`, `with-exception-handler`)
- Catchable assertion errors from ECE code

## Decisions

### 1. Pure ECE macro in prelude

`assert` is a macro that expands to an `if`/`error` check. No CL-side changes needed.

### 2. Optional message with default

- `(assert expr)` signals `"Assertion failed"` on failure
- `(assert expr "custom message")` signals the custom message

The macro checks whether a message argument is provided and expands accordingly.

## Risks / Trade-offs

None — trivial addition with no impact on existing code.
