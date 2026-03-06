## 1. Add I/O Primitives

- [x] 1.1 Add `read` (with `*read-eval*` nil), `print`, `display` (princ), and `newline` to primitive procedures
- [x] 1.2 Add tests verifying I/O primitives are bound in `*global-env*`

## 2. Add Error-Handling and EOF Primitives

- [x] 2.1 Add a `try-eval` primitive that wraps `evaluate` with `handler-case`, returning the result or printing the error and returning nil
- [x] 2.2 Add a safe `read` wrapper that catches `end-of-file` and returns a sentinel EOF value
- [x] 2.3 Add an `eof?` primitive to test for the EOF sentinel

## 3. Implement REPL as ECE Function

- [x] 3.1 Implement `ece:repl` CL function that bootstraps the REPL by evaluating a `define`'d tail-recursive ECE loop
- [x] 3.2 Export `repl` from the `ece` package

## 4. Documentation

- [x] 4.1 Update README.md with REPL usage instructions
