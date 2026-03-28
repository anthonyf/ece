## 1. Fix

- [x] 1.1 Add `letrec-make-sets` helper function in `prelude.scm` — walks two lists (vars, tmps) in parallel to produce `(set! var tmp)` forms.
- [x] 1.2 Rewrite `letrec` macro in `prelude.scm` — use lambda-argument evaluation: `(let ((vars...)) ((lambda (tmps...) (set! var tmp)... body) inits...))`.
- [x] 1.3 Run `make bootstrap` to regenerate `prelude.ecec`.

## 2. Tests

- [x] 2.1 Verify pitfall test 1.1 passes: `(let ((cont #f)) (letrec ((x (call/cc ...)) (y (call/cc ...))) ...))` returns 0.
- [x] 2.2 Run `make test-conformance` — expect 0 failures (all 150 pass or skip).
- [x] 2.3 Verify existing ECE tests still pass (0 failures).
