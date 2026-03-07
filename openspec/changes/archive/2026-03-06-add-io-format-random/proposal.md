## Why

ECE needs I/O, formatting, and randomness primitives to support interactive fiction and general-purpose programming. `read-line` enables raw text input (not just s-expressions). `write-to-string` and formatting macros enable string interpolation for narrative text. Bitwise primitives and a seedable xorshift32 PRNG provide deterministic randomness — essential for reproducible game sessions, dice rolls, and random events — while keeping continuations serializable.

## What Changes

- Add `read-line` primitive (CL `read-line` wrapper) for raw text input
- Add `write-to-string` primitive (CL `princ-to-string` wrapper) for converting any value to its string representation
- Add bitwise primitives: `bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift` (mapped to CL `logand`, `logior`, `logxor`, `lognot`, `ash`)
- Add xorshift32 PRNG implemented in ECE using the bitwise primitives: `random`, `random-seed!`, with `*random-state*` as a global variable
- Add `fmt` macro for string interpolation (concatenates args, auto-converting non-strings via `write-to-string`)
- Add `print-text` macro for displaying formatted text (like `fmt` but outputs via `display` instead of returning a string)

## Capabilities

### New Capabilities
- `read-line`: Raw text input primitive returning a string
- `write-to-string`: Value-to-string conversion primitive
- `bitwise-ops`: Bitwise arithmetic primitives (and, or, xor, not, shift)
- `xorshift-random`: Seedable xorshift32 PRNG using bitwise primitives
- `format-macros`: `fmt` and `print-text` macros for string interpolation and formatted output

### Modified Capabilities
- `primitive-proc-tests`: New primitives need test coverage

## Impact

- `src/main.lisp`: New primitive registrations, wrapper functions for read-line and write-to-string
- `tests/main.lisp`: New test suites for all added capabilities
- ECE standard library: xorshift32 PRNG, `fmt`, and `print-text` can be implemented as ECE code loaded via the evaluator or defined in the initial environment
