## Context

3 WASM test failures remain after the platform hash tables change. All are in `$apply-primitive` in `runtime.wat`.

## Goals / Non-Goals

**Goals:**
- Fix all 3 failures
- 329/329 common tests pass on WASM

**Non-Goals:**
- New features or primitives

## Decisions

### 1. hash-ref default argument

`hash-ref` is variadic (arity -1). When called with 3 args `(hash-ref ht key default)`, the 3rd arg should be returned if the key is not found. Current code always returns `#f`. Fix: after `$hash-ref-impl` returns `$false`, check if argl has a 3rd element and return it instead.

### 2. string->number

Identify the exact failing input by running the test and tracing. Likely a parser edge case with `"0"` or float format. Fix the WAT parser accordingly.

### 3. make-parameter converter

`(make-parameter val converter)` should apply `converter` to `val` before storing. Calling a compiled procedure from within a WAT primitive requires re-entering the executor, which is complex. Simpler approach: handle the converter in the ECE prelude wrapper instead of the primitive — define `make-parameter` as an ECE function that calls the converter then calls `%make-parameter-raw` (a new primitive that just stores the value).

Alternatively, since the prelude already defines `make-parameter` in ECE on the CL host, check if the prelude wrapper handles the converter. If it does, the WASM primitive just needs to store the value (same as now) and the prelude wrapper calls the converter before calling the primitive.
