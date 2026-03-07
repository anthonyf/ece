## 1. CL-Side Primitives

- [x] 1.1 Add `ece-read-line` wrapper function and register `read-line` primitive via dolist
- [x] 1.2 Add `ece-write-to-string` wrapper function (using `princ-to-string`) and register `write-to-string` primitive via dolist
- [x] 1.3 Add bitwise primitives to the primitive alist: `bitwise-and`→`logand`, `bitwise-or`→`logior`, `bitwise-xor`→`logxor`, `bitwise-not`→`lognot`, `arithmetic-shift`→`ash`
- [x] 1.4 Add package exports for `read-line`, `write-to-string`, `bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`, `random`, `random-seed!`, `*random-state*`, `fmt`, `print-text`

## 2. ECE-Level Definitions

- [x] 2.1 Add xorshift32 PRNG: evaluate `*random-state*`, `random-seed!`, `xorshift32`, and `random` definitions during initialization
- [x] 2.2 Add `fmt` macro via evaluate during initialization
- [x] 2.3 Add `print-text` macro via evaluate during initialization

## 3. Tests

- [x] 3.1 Add tests for `write-to-string` (number, symbol, string, boolean, list, empty list)
- [x] 3.2 Add tests for bitwise primitives (and, or, xor, not, arithmetic-shift)
- [x] 3.3 Add tests for xorshift32 PRNG (range check, seed reproducibility, state changes)
- [x] 3.4 Add tests for `fmt` macro (strings, mixed types, single arg)
- [x] 3.5 Run full test suite and verify all tests pass
