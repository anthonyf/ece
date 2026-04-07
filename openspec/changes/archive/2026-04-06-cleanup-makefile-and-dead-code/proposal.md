## Why

A code review identified several low-hanging-fruit issues in the Makefile and runtime.lisp: duplicated Makefile targets, a temp directory created on every `make` invocation regardless of target, and dead legacy parameter code that was never cleaned up after the env-stored-parameters migration completed.

## What Changes

- **Deduplicate `run`/`repl` targets**: `run` and `repl` are byte-for-byte identical (both call `(ece:repl)`). Make `run` delegate to `repl`.
- **Deduplicate `clean`/`clean-fasl` targets**: Both just `rm -rf .fasl-cache/`. Make `clean-fasl` an alias for `clean`.
- **Lazy `TEST_OUTPUT_DIR`**: Change from `:=` (parse-time) to recipe-local evaluation so `make clean`, `make fmt`, etc. don't create orphan temp dirs.
- **Remove dead legacy parameter code**: Delete `*parameter-table*`, `*parameter-counter*`, and `ece-make-parameter-legacy` from runtime.lisp. The env-stored-parameters migration is complete — `ece-make-parameter-legacy` has zero call sites.

## Capabilities

### New Capabilities

_None — this is cleanup only._

### Modified Capabilities

- `makefile`: Deduplicate targets, lazy temp dir creation

## Impact

- **Makefile**: 4 targets modified, no behavior change for users
- **runtime.lisp**: ~12 lines of dead code removed (parameter legacy shim)
- **No test changes needed** — no behavior changes, only dead code removal and build hygiene
