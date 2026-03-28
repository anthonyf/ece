## 1. Add primitive

- [x] 1.1 Add `eqv?` primitive in runtime.lisp mapping to CL's `eql`, wrapped with scheme-bool. Also added to primitives.def (ID 174) and package exports.
- [x] 1.2 Clear FASL cache and verify `(eqv? 'a 'a)` returns #t.

## 2. Enable tests

- [x] 2.1 Unskip test 4.3 (now passes), re-skip 5.2 as CL nil divergence with real test expression.
- [x] 2.2 Add 6 eqv? tests to chibi-r5rs.scm.
- [x] 2.3 Run `make test-conformance`: 148 passed, 0 failed, 8 skipped.
- [x] 2.4 Verify existing ECE tests still pass (0 failures).
