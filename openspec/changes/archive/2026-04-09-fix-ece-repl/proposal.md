## Why

Running the installed `ece` binary crashes with "Unbound variable: repl" because `ece-main.scm` calls `repl` as an ECE-level function, but `repl` is only defined as a CL-side function in `runtime.lisp:2461` — never exposed to the ECE environment. The REPL needs to be defined in ECE so it's available when the compiled `.ecec` bytecode runs.

## What Changes

- Define `repl` as an ECE function in `src/ece-main.scm`, using the same logic as the CL version (prompt → read → try-eval → write → loop)
- Remove the CL-side `repl` function from `src/runtime.lisp` (lines 2460-2475)
- Rebootstrap to recompile `ece-main.ecec`

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- `src/ece-main.scm` — new `repl` definition added
- `src/runtime.lisp` — dead CL-side `repl` function removed
- `bootstrap/bootstrap.ecec` and `share/ece/ece-main.ecec` — recompiled via `make bootstrap`
- Installed binary (`bin/ece`) — will work after rebuild + reinstall
