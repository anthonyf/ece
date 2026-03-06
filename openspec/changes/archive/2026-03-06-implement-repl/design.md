## Context

The evaluator now supports `define` with function shorthand and tail call optimization. This means a REPL loop can be expressed as a tail-recursive ECE function rather than requiring a CL-side loop. CL's `read` and `print` are standard functions that handle s-expression I/O. Additional I/O primitives (`display`, `newline`) are needed for prompt output without `print`'s leading newline.

## Goals / Non-Goals

**Goals:**
- Add `read`, `print`, `display`, and `newline` as primitive procedures
- Implement the REPL loop as a tail-recursive ECE function using `define`
- Handle errors gracefully (print the error, continue the loop)
- Provide a clean prompt (e.g., `ece> `)
- Safe read: bind `*read-eval*` to `nil` to prevent `#.` code execution

**Non-Goals:**
- Line editing, history, or tab completion
- Custom reader macros or printer

## Decisions

**REPL in ECE, not CL**: The REPL loop is defined as an ECE function using `define` and tail recursion. The CL-side `ece:repl` function is just a bootstrap that defines the loop function and calls it. This exercises the language itself and demonstrates that ECE is powerful enough to implement its own REPL.

**I/O primitives**: `read` (zero-arg, reads from `*standard-input*` with `*read-eval*` nil), `print` (one-arg, CL `print`), `display` (one-arg, writes without leading newline — uses `princ`), `newline` (zero-arg, writes a newline). `display` and `newline` are needed because `print` adds a leading newline which is wrong for prompts.

**Error handling via primitive**: Add an `eval` primitive that wraps `evaluate` with error handling — catches conditions, prints the error, and returns nil. The REPL loop calls `eval` instead of directly evaluating, so errors don't crash the tail-recursive loop. This avoids needing try/catch in ECE itself.

**EOF handling**: Wrap the `read` primitive to catch `end-of-file` conditions and return a sentinel EOF value. The REPL loop checks for this sentinel and exits cleanly.

## Risks / Trade-offs

- [`read` uses CL's reader] → ECE programs share CL's syntax exactly, which is the intent
- [No `display` vs `print` distinction in Scheme sense] → We add both: `print` (CL convention with newline+space) and `display` (raw output via `princ`)
- [Error handling in primitive, not language] → ECE doesn't have try/catch, so wrapping `evaluate` in a CL error handler is pragmatic
