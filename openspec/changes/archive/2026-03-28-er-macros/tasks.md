## 1. Compiler: %global-ref

- [x] 1.1 Add `mc-global-ref?` predicate and `mc-compile-global-ref` to compiler.scm — compiles to `lookup-variable-value` bypassing lexical scope.
- [x] 1.2 Add `%global-ref` to `*mc-special-forms*` list and `mc-compile` dispatch.

## 2. Syntax-rules: wrap free variables

- [x] 2.1 Modify `syntax-instantiate` in syntax-rules.scm — wrap non-pattern-variable, non-renamed symbols in `(%global-ref sym)` instead of emitting bare symbols.
- [x] 2.2 Verify `(let-syntax ((foo (syntax-rules () ((_ e) (+ e 1))))) (let ((+ *)) (foo 3)))` returns 4.

## 3. Bootstrap and test

- [x] 3.1 Double bootstrap (compiler change needs two passes).
- [x] 3.2 Unskip pitfall test 3.1.
- [x] 3.3 Run `make test-conformance` — target: 157 passed, 0 failed, 0 skipped.
- [x] 3.4 Verify existing ECE tests still pass.
