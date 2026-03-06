## Why

There's currently no way to interactively use the ECE language — you have to call `(ece:evaluate ...)` from a CL REPL. A proper REPL (Read-Eval-Print Loop) makes the language usable as a standalone interactive environment. With `define` and TCO now implemented, the REPL loop can be written as a tail-recursive ECE function rather than a CL-side loop.

## What Changes

- Add CL's `read`, `print`, and I/O helper primitives (`display`, `newline`) to `*global-env*`
- Add an `ece:repl` CL function that bootstraps the ECE REPL by evaluating a `define`'d tail-recursive loop function
- The REPL loop itself is an ECE function: prompts, reads, evaluates, prints, and recurses
- Safe read: bind `*read-eval*` to `nil` during read
- Add a command-line entry point so the REPL can be launched with `qlot exec sbcl --load ece.asd --eval '(ece:repl)'`

## Capabilities

### New Capabilities
- `repl`: Interactive Read-Eval-Print Loop for the ECE language, implemented as an ECE function

### Modified Capabilities

## Impact

- `src/main.lisp`: Add I/O primitives, add `repl` bootstrap function, export `repl`
- `README.md`: Update with REPL usage instructions
