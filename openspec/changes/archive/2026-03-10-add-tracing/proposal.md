## Why

Debugging compiled ECE procedures requires inserting print statements, recompiling, and re-running — a slow feedback loop. A `(trace foo)` / `(untrace foo)` facility would let developers observe procedure entry/exit with arguments and return values in real-time, without modifying source code.

## What Changes

- Add `(trace <name>)` to enable tracing on a procedure — logs each call with arguments and return value, indented by call depth
- Add `(untrace <name>)` to disable tracing and restore the original procedure
- Tracing works for both compiled procedures and primitives
- Traced calls display depth-indented entry/exit with arguments and return values
- Implement as primitive wrappers: `trace` replaces the procedure binding with a primitive that logs entry, delegates to the original, and logs exit
- Add `execute-compiled-call` runtime helper to re-enter the executor with proc/argl pre-loaded for calling compiled procedures from tracing wrappers

## Capabilities

### New Capabilities
- `tracing`: Procedure tracing facility — `trace`/`untrace` forms, wrapper-based delegation, depth-indented output

### Modified Capabilities

## Impact

- `src/runtime.lisp` — new tracing infrastructure (`*traced-procedures*`, `*trace-depth*`, `execute-compiled-call`), new primitives (`trace`, `untrace`)
- `src/compiler.lisp` — register `trace`/`untrace` as special forms or primitives
- `tests/ece.lisp` — new test suite for tracing behavior
