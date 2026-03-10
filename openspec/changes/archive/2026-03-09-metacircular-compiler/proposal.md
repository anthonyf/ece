## Why

ECE's compiler (`compiler.lisp`, 579 lines of CL) currently compiles Scheme expressions to register machine instructions per SICP 5.5. Rewriting this compiler in ECE itself (`compiler.scm`) achieves self-hosting: the language can compile itself. With image save/load already working, this enables a bootstrap sequence where `runtime.lisp` + a saved image replaces the need for `compiler.lisp` entirely, making ECE portable to any backend that implements the runtime (e.g., JSCL for browser deployment).

## What Changes

- Add `union` and `set-difference` to the ECE prelude (needed by instruction sequence combinators)
- Expose `assemble-into-global` as an ECE primitive (the compiler needs to emit into the global instruction vector)
- Add `execute-from-pc` primitive (run instructions starting at a given PC, returning the val register)
- Create `src/compiler.scm` — the metacircular compiler, a faithful port of `compiler.lisp` into ECE
- Add `compile-and-go` and `evaluate` as ECE-level functions (compile + assemble + execute)
- The CL `compiler.lisp` remains as the reference implementation and bootstrap compiler
- All existing tests must pass when compiled by the new ECE compiler

## Capabilities

### New Capabilities
- `metacircular-compiler`: Self-hosting ECE compiler written in ECE, covering all expression types (self-evaluating, variables, quote, quasiquote, if, begin, lambda, define, set, call/cc, apply, define-macro, procedure application) with instruction sequence optimization (preserving, parallel sequences)

### Modified Capabilities
- `compiler-core`: Add `union`, `set-difference` to prelude; expose `assemble-into-global` and `execute-from-pc` as primitives

## Impact

- **New file**: `src/compiler.scm` (~500-600 lines)
- **Modified**: `src/prelude.scm` (add `union`, `set-difference`)
- **Modified**: `src/runtime.lisp` (register new primitives: `assemble-into-global`, `execute-from-pc`)
- **Modified**: `src/compiler.lisp` (register new primitives in global env)
- **Modified**: `tests/ece.lisp` (add metacircular compiler tests)
- **Load order**: runtime.lisp -> compiler.lisp -> prelude.scm -> compiler.scm
- **No breaking changes**: CL compiler remains, metacircular compiler is additive
