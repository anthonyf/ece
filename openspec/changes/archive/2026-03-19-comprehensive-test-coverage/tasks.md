## 1. Cross-Space Execution (test-cross-space.scm)

- [x] 1.1 Test: user-defined function calls prelude function (map, filter) — verifies cross-space call from bootstrap→prelude
- [x] 1.2 Test: user code calls compiler function (mc-compile-and-go, eval) — verifies bootstrap→compiler
- [x] 1.3 Test: continuation captured in user code, invoked — crosses space boundary on return
- [x] 1.4 Test: load a .scm file, call function defined in it — new space→bootstrap cross-space call

## 2. Mutation Primitives (test-mutation.scm)

- [x] 2.1 Test: set-car! modifies pair, car returns new value
- [x] 2.2 Test: set-cdr! modifies pair, cdr returns new value
- [x] 2.3 Test: mutation visible through shared reference (two variables pointing to same pair)
- [x] 2.4 Test: mutation inside a closure affects outer scope

## 3. File I/O (test-file-io.scm)

- [x] 3.1 Test: open-output-file, write-char, close-output-port — creates file with content
- [x] 3.2 Test: open-input-file, read-char, close-input-port — reads back written content
- [x] 3.3 Test: peek-char returns next char without consuming it
- [x] 3.4 Test: with-input-from-file reads file content
- [x] 3.5 Test: with-output-to-file writes file content
- [x] 3.6 Test: eof detection with read-char

## 4. Advanced Continuations (test-advanced-continuations.scm)

- [x] 4.1 Test: invoke continuation multiple times — each invocation produces correct result
- [x] 4.2 Test: continuation used as a coroutine (ping-pong between two continuations)
- [x] 4.3 Test: continuation captured inside parameterize, invoked outside — parameter value restored
- [x] 4.4 Test: nested parameterize with continuation capture and invoke
- [x] 4.5 Test: continuation captured, value mutated after capture, invoke sees mutation (mutable state is shared)

## 5. Miscellaneous Features (test-misc.scm)

- [x] 5.1 Test: bitwise-and, bitwise-or, bitwise-xor, bitwise-not, arithmetic-shift
- [x] 5.2 Test: random returns number in range, random-seed! affects sequence
- [x] 5.3 Test: write-to-string for various types (number, string, list, boolean, vector, hash-table)
- [x] 5.4 Test: write-to-string-flat produces ECE-reader-compatible output
- [x] 5.5 Test: keyword? returns #t for keywords, #f for non-keywords
- [x] 5.6 Test: platform-has? returns boolean for known primitives
- [x] 5.7 Test: named let (loop with accumulator)
- [x] 5.8 Test: loop macro with break
- [x] 5.9 Test: collect macro (list comprehension)
- [x] 5.10 Test: macro shadowing — lambda param and define with same name as macro

## 6. Integration

- [x] 6.1 Add all new test files to run-all.scm
- [x] 6.2 Run full test suite — 484 ECE native + all CL tests pass
