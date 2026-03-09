## Why

ECE is currently a pure interpreter — every expression goes through a 13-way type dispatch and ~48 label transitions per loop iteration, with ~44 stack operations that are often unnecessary. Adding a compiler that targets the same register machine eliminates dispatch overhead, removes unnecessary save/restore operations, and resolves macro expansion at compile time. Following SICP Chapter 5.5, the compiler replaces the interpreter entirely: `evaluate` becomes `compile-and-go`, giving compiled speed everywhere including the REPL.

## What Changes

- Add a `compile` function that translates ECE expressions into register machine instruction sequences, following the SICP 5.5 design
- Instruction sequences carry register metadata (needs/modifies) enabling the `preserving` combinator to eliminate unnecessary save/restore operations
- Macro expansion happens at compile time, not runtime
- Add an instruction executor that runs compiled instruction sequences on the existing register machine (stack, conts, val, unev, argl, proc, env)
- Replace the interpreter's `evaluate` with `compile-and-go` — compile the form, then execute the instructions
- Remove the interpreter dispatch loop (the ~1200-line `case` statement) once the compiler handles all forms
- `compile-file` compiles all forms in a file (used for prelude and user code)
- Compiled and primitive procedures coexist: primitives remain CL functions, compiled procedures are instruction sequences with captured environments

## Capabilities

### New Capabilities
- `compiler-core`: The `compile` function, instruction sequence representation, `preserving` combinator, and compilation of all expression types (self-eval, variable, quoted, if, lambda, begin, application, define, set, call/cc, define-macro, quasiquote, apply)
- `instruction-executor`: The instruction executor loop that runs compiled instruction sequences on the register machine registers
- `compile-and-go`: `compile-and-go` entry point that replaces `evaluate`, plus `compile-file` for batch compilation

### Modified Capabilities
- `callcc-special-form`: `call/cc` must work with compiled procedures — continuation capture/restore operates on the same stack/conts registers

## Impact

- `src/ece.lisp`: Major rewrite — interpreter dispatch loop replaced by compiler + executor
- `src/prelude.scm`: No changes (compiled transparently by `compile-file`)
- `tests/ece.lisp`: All existing tests should pass unchanged (they call `evaluate` which now compiles internally)
- Expected 3-5x speedup on compute-heavy code
