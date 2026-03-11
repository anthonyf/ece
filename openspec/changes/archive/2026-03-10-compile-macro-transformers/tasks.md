## 1. Update compiler.scm

- [x] 1.1 Rewrite `mc-compile-define-macro` to compile the transformer as `(lambda params . body)` via `mc-compile-and-go` and store the compiled procedure in the macro table via `set-macro!`
- [x] 1.2 Rewrite `mc-expand-macro-at-compile-time` to call the compiled transformer procedure with the unevaluated operands list (using `apply-compiled-procedure` or equivalent) and return the result

## 2. Update runtime.lisp

- [x] 2.1 Update `*compile-time-macros*` docstring to reflect that it stores compiled procedures instead of `(params body env)` tuples
- [x] 2.2 Add `apply-compiled-procedure` primitive (call a compiled procedure with a list of args) if not already available — or confirm `execute-compiled-call` is exposed to ECE

## 3. Regenerate bootstrap image

- [x] 3.1 Run `make image` to regenerate bootstrap/ece.image with compiled macro transformers

## 4. Verify

- [x] 4.1 Run `make test` — all existing tests pass
- [x] 4.2 Run `make run` — REPL starts, macros (cond, let, when, etc.) work
