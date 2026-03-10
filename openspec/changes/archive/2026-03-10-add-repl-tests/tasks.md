## 1. Test Helper

- [x] 1.1 Add `run-repl` helper function to `tests/ece.lisp` that takes an input string, redirects `ece::*current-input-port*` to a string port, captures `*standard-output*`, calls `ece:repl`, and returns the captured output string

## 2. REPL Tests

- [x] 2.1 Test simple expression: integer literal `42` → output contains `42`
- [x] 2.2 Test arithmetic: `(+ 1 2)` → output contains `3`
- [x] 2.3 Test multiple expressions: `1`, `2`, `3` → all results appear with multiple prompts
- [x] 2.4 Test define variable: `(define repl-test-x 10)` then `repl-test-x` → output contains `10`
- [x] 2.5 Test define function (crash regression): `(define (repl-test-plus a b) (+ a b))` then `(repl-test-plus 3 4)` → output contains `REPL-TEST-PLUS` and `7`
- [x] 2.6 Test error recovery: unbound variable followed by valid expression → output contains `Error:` and correct result
- [x] 2.7 Test string output: `"hello"` → output contains quoted `"hello"`
- [x] 2.8 Test boolean `#t` → output contains `T`; test `#f` → no result value printed
- [x] 2.9 Test lambda printing: `(lambda (x) x)` → output contains `procedure`, no crash
- [x] 2.10 Test EOF/goodbye: after input exhausted → output contains `Bye!`
- [x] 2.11 Test prompt: output contains `ece> `
