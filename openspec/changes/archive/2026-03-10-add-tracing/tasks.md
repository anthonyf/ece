## 1. Runtime Infrastructure

- [x] 1.1 Add `*traced-procedures*` defvar (hash table, symbol keys → original procedure values)
- [x] 1.2 Add `*trace-depth*` defvar (integer, starts at 0)
- [x] 1.3 Add `execute-compiled-call` — extend `execute-instructions` with `:initial-proc` and `:initial-argl` keyword args, add thin wrapper that calls it with the compiled procedure's entry PC

## 2. Trace/Untrace Implementation

- [x] 2.1 Implement `ece-trace` — look up procedure in `*global-env*`, store original in `*traced-procedures*`, create a primitive wrapper that logs entry/exit with depth indentation and delegates to original, replace binding in `*global-env*`
- [x] 2.2 Implement `ece-untrace` — look up original in `*traced-procedures*`, restore binding in `*global-env*`, remove from table. No-op if not traced.

## 3. Primitive Registration

- [x] 3.1 Add `trace` and `untrace` to `*wrapper-primitives*` so they are available in the ECE global environment

## 4. Tests

- [x] 4.1 Test that tracing a compiled procedure produces entry/exit output and returns the correct value
- [x] 4.2 Test that tracing a primitive procedure produces entry/exit output and returns the correct value
- [x] 4.3 Test that untrace restores original behavior (no trace output)
- [x] 4.4 Test that nested traced calls show increasing indentation
- [x] 4.5 Test that untrace on a non-traced procedure does not error
