## Why

ECE is a monolithic 1391-line file containing the runtime, compiler, readtable, and primitives all interleaved. Extracting the minimal runtime into a separate file enables: (1) porting just the runtime to JSCL for browser-based execution of pre-compiled ECE programs, and (2) eventually rewriting the compiler in ECE itself (metacircular compiler), where the runtime is the only CL that needs to exist.

## What Changes

- Create `src/runtime.lisp` containing the minimal code needed to execute compiled ECE instructions: environment operations, executor, procedure/continuation types, primitive registration, global state, and assembler
- Create `src/compiler.lisp` containing the compiler: instruction sequence combinators, compile dispatch, all `compile-*` functions, macro expansion, readtable, and `compile-and-go`/`compile-file-ece`
- Remove `src/ece.lisp` — replaced by `runtime.lisp` + `compiler.lisp`
- Update `ece.asd` to load `runtime.lisp` before `compiler.lisp`
- The package definition (`defpackage #:ece`) moves to `runtime.lisp` with all exports
- `compiler.lisp` opens the same package with `(in-package :ece)`

## Capabilities

### New Capabilities

- `runtime-separation`: The runtime and compiler are separate files that can be loaded independently. The runtime alone is sufficient to execute pre-compiled instruction vectors.

### Modified Capabilities

_None — no behavioral changes._

## Impact

- `src/ece.lisp` removed, replaced by `src/runtime.lisp` + `src/compiler.lisp`
- `ece.asd` updated with new component list
- All existing tests must pass unchanged
- Public API unchanged (`evaluate`, `repl`, `*global-env*`, all exports)
