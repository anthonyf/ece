## 1. Add helper functions

- [x] 1.1 Add `$xcar` and `$xcdr` functions (casting variants) after existing `$car`/`$cdr` definitions
- [x] 1.2 Add `$cadr` and `$caddr` composed accessors

## 2. Rewrite call sites

- [x] 2.1 Replace all `(call $car (ref.cast (ref $pair) <local/expr>))` with `(call $xcar <local/expr>)`
- [x] 2.2 Replace all `(call $cdr (ref.cast (ref $pair) <local/expr>))` with `(call $xcdr <local/expr>)`
- [x] 2.3 Replace all cadr patterns `(call $car (ref.cast (ref $pair) (call $cdr ...)))` with `(call $cadr ...)`
- [x] 2.4 Replace all caddr patterns with `(call $caddr ...)`

## 3. Validation

- [x] 3.1 Run WASM test suite — all must pass
- [x] 3.2 Run CL test suite (rove + ECE self-hosted + conformance) — no regressions
