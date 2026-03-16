## 1. Merge boot.lisp into runtime.lisp

- [x] 1.1 Move image load call, `evaluate`, `ece-try-eval`, and `repl` definitions from `boot.lisp` to the bottom of `runtime.lisp`
- [x] 1.2 Remove `boot.lisp` from `"ece"` ASDF system components
- [x] 1.3 Remove `readtable.lisp` from `"ece"` ASDF system components
- [x] 1.4 Ensure `"ece/cold"` ASDF system still loads `readtable.lisp` and `compiler.lisp`

## 2. Migrate test helper

- [x] 2.1 Rewrite `ece-eval-string` in `tests/ece.lisp` to use `mc-eval` with ECE reader (`open-input-string` + `read` + `eval`) instead of `*ece-readtable*`
- [x] 2.2 Remove `*ece-readtable*` reference from test file

## 3. Convert tests with #f/#t in quoted s-expressions

- [x] 3.1 Find all tests using `#f` or `#t` inside `(evaluate '(...))` forms and convert to `(ece-eval-string "...")` — none found, tests already use *scheme-false* or ece-eval-string

## 4. Verify

- [x] 4.1 Run full test suite and confirm all tests pass (only pre-existing test-error-context failure remains)
- [x] 4.2 Verify `(asdf:load-system :ece)` loads only `runtime.lisp` and the image
- [x] 4.3 Save a new bootstrap image from the updated system
