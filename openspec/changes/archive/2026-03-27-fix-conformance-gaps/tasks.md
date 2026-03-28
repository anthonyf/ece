## 1. Named Let Init Scope

- [x] 1.1 Fix named let expansion in `prelude.scm` — change to `((letrec ((name (lambda (vars) body))) name) inits...)` so inits evaluate outside letrec scope.
- [x] 1.2 Verify `(let - ((n (- 1))) n)` returns `-1`.

## 2. Special Form Shadowing

- [x] 2.1 Add lexical scope check in `mc-compile` (compiler.scm) — if `(car expr)` is lexically bound, skip special form dispatch and compile as application.
- [x] 2.2 Verify `((lambda (begin) (begin 1 2 3)) (lambda lambda lambda))` returns `(1 2 3)` (pitfall test 4.2 passes).

## 3. Procedure? Shim

- [x] 3.1 Update `procedure?` in `chibi-r5rs.scm` to recognize continuations (`(continuation ...)` pairs).
- [x] 3.2 Investigate the `(symbol? 'nil)` failure — actually `(symbol? '())` returning #t due to CL nil. Fundamental divergence, skipped.

## 4. Bootstrap and Verify

- [x] 4.1 Run `make bootstrap` to regenerate `.ecec` files.
- [x] 4.2 Run `make test-conformance` and confirm reduced failure count.
- [x] 4.3 Verify existing ECE tests still pass (0 failures).
