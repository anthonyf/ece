## Why

ECE programs can only be entered interactively or embedded in CL code. There's no way to run an ECE source file. `load` is the standard Scheme mechanism for this and enables building programs across multiple files.

## What Changes

- Add `load` as a CL-side primitive that opens a file, reads all expressions with the ECE readtable, and evaluates each one in sequence
- Fail-fast on errors (unlike the REPL which continues after errors)
- Export `load` from the ECE package

## Capabilities

### New Capabilities
- `load-file`: The `load` primitive for reading and evaluating ECE source files

### Modified Capabilities

## Impact

- `src/main.lisp`: New `ece-load` wrapper function, register as primitive, export symbol
- `tests/main.lisp`: Test loading a temporary file with ECE expressions
