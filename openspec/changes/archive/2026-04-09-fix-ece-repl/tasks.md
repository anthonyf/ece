## 1. Define REPL in ECE

- [x] 1.1 Add `repl` function definition to `src/ece-main.scm` (before its call sites), using `display`, `read`, `try-eval`, `write`, `eof?`
- [x] 1.2 Remove the CL-side `repl` function from `src/runtime.lisp` (lines 2460-2475)
- [x] 1.3 Update `make repl` Makefile target to load ece-main.ecec and call ECE `repl` instead of CL `(ece:repl)`

## 2. Bootstrap and verify

- [x] 2.1 Run `make bootstrap` to recompile .ecec files with new `repl` definition
- [x] 2.2 Run `make test` — all test suites pass
- [x] 2.3 Run `make repl` — REPL starts, accepts input, exits on EOF (error recovery is pre-existing known issue with ecec boot)
- [x] 2.4 Run `make install PREFIX=~/.local` then `ece` — REPL starts correctly
