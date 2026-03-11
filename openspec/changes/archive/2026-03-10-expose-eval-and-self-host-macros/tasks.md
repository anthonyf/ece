## 1. Expose `eval`

- [x] 1.1 Define `(eval expr)` in `compiler.scm` after `mc-compile-and-go` as a wrapper that calls `mc-compile-and-go`
- [x] 1.2 Add tests for `eval`: literal, arithmetic, define, lambda+call

## 2. Self-host macro expansion

- [x] 2.1 Add optional environment parameter to `execute-from-pc` CL primitive so compiled code can execute in a non-global environment
- [x] 2.2 Update `mc-compile-and-go` in `compiler.scm` to accept an optional environment argument and pass it to `execute-from-pc`
- [x] 2.3 Rewrite `mc-expand-macro-at-compile-time` in `compiler.scm` to use `extend-environment` + `mc-compile-and-go` instead of delegating to CL `expand-macro` primitive
- [x] 2.4 Expose `extend-environment` as a callable primitive (register in `*wrapper-primitives*` and export)
- [x] 2.5 Add tests verifying macro expansion still works: simple macros, macros using stdlib macros, lexical shadowing

## 3. Verification

- [x] 3.1 Run full test suite and confirm all existing tests pass (macro-dependent tests like `cond`, `let`, `when`, etc. exercise the new expansion path)
