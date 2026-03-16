## Why

ECE's current `load` tightly couples reading, compiling, and executing — every form is `mc-compile-and-go`'d immediately. There's no intermediate representation you can inspect, cache, or serialize independently. Most mature Lisps (CL's FASL, Chez's `.so`, Guile's `.go`) separate compilation from execution via compilation units. Adding this to ECE gives a cleaner architecture, enables compiled file caching, and provides an inspectable intermediate form useful for debugging the compiler.

## What Changes

- Add `compile-form` as the core primitive: compiles a single expression and returns a first-class **compiled unit** value
- Add `compiled-unit?`, `compiled-unit-instructions` for inspecting compiled units
- Add `execute` to run a compiled unit against the global environment
- Add `write-compiled-unit` / `read-compiled-unit` for serializing compiled units to/from ports as s-expressions
- Add `compile-file` that compiles all forms in a `.scm` file, producing a `.ecec` compiled file (executing macro definitions at compile time so subsequent forms can use them)
- Add `load-compiled` that loads and executes a compiled `.ecec` file
- All new code is implemented in ECE (Scheme), not CL — `mc-compile` is already self-hosted

## Capabilities

### New Capabilities
- `compiled-unit`: First-class compiled unit values — creation via `compile-form`, predicate, accessor, execute, and serialization/deserialization
- `compile-file`: File-level compilation (`compile-file`) and loading (`load-compiled`) with compile-time macro execution

### Modified Capabilities

## Impact

- `src/compiler.scm` — new `compile-form` wrapper around `mc-compile`
- `src/assembler.scm` — new `execute`, `write-compiled-unit`, `read-compiled-unit`, `compile-file`, `load-compiled`
- `src/prelude.scm` — export new primitives
- No CL kernel changes needed — builds entirely on existing `mc-compile` and `assemble-into-global`
- No breaking changes to existing `load` or `mc-compile-and-go`
