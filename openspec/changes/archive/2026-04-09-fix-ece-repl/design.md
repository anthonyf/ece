## Context

The `repl` function is defined in CL (`runtime.lisp:2461`) but called from ECE bytecode (`ece-main.ecec`). The CL function uses `evaluate` to compile and run a REPL loop at runtime. This worked when `ece-main.scm` was loaded via `make repl` (CL-side `evaluate` call), but breaks in the installed binary where `ece-main.ecec` runs as compiled bytecode — the CL function is invisible to the ECE environment.

## Goals / Non-Goals

**Goals:**
- `ece` and `ece-repl` commands start a working REPL after installation
- REPL behavior is identical to the current CL implementation (prompt, read, eval, print, loop)
- No impact on WASM host (WASM uses event-driven eval, never calls `repl`)

**Non-Goals:**
- Changing REPL features (history, completion, multi-line input)
- Making `repl` available as a library function — it belongs to the CLI tool only

## Decisions

**Define `repl` in `ece-main.scm`, not `prelude.scm`**

The REPL is a CLI tool concern, not a language primitive. Putting it in `ece-main.scm` keeps it out of the bootstrap loaded by all hosts. WASM never needs it.

**Use existing ECE primitives: `display`, `read`, `try-eval`, `write`, `eof?`**

These are all available in the ECE environment. `try-eval` is a registered primitive (ID in manifest) that wraps `evaluate` with error handling — on error it prints the message and returns the EOF sentinel. The CL version already uses this pattern.

**Remove the CL-side `repl` function**

It's dead code once the ECE version exists. The `make repl` Makefile target calls `(ece:repl)` — this CL function will need to either be kept for that target or the target updated to use `evaluate` to call the ECE `repl` directly.

## Risks / Trade-offs

**`make repl` target** — Currently calls CL-side `(ece:repl)`. After removing the CL function, this target needs updating. Simplest fix: have it call `(evaluate '(repl))` after loading the bootstrap + ece-main.ecec.
