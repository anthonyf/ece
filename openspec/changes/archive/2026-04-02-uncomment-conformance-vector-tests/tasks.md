## 1. Uncomment vector tests in chibi-r5rs.scm

- [x] 1.1 Uncomment line 122: do-loop vector construction test
- [x] 1.2 Uncomment line 170: `(equal? (make-vector 5 'a) (make-vector 5 'a))` test
- [x] 1.3 Reconstruct and uncomment line 260: vector-set! with nested data (expand the `...`)
- [x] 1.4 Uncomment line 261: `(list->vector '(dididit dah))` test
- [x] 1.5 Uncomment line 277: for-each squared vector test
- [x] 1.6 Remove the stale `; skipped: equal? doesn't deeply compare vectors` comments

## 2. Remove dead skip mechanism from conformance-framework.scm

- [x] 2.1 Remove `*conformance-skip-list*`, `*conformance-skips*`, `conformance-skip!`, `conformance-skipped?`
- [x] 2.2 Simplify `conformance-test` macro to remove the skip branch
- [x] 2.3 Remove skip count from `conformance-summary` display

## 3. Update baselines and verify

- [x] 3.1 Run `make test` — all suites must pass
- [x] 3.2 Update `tests/test-counts.json` conformance baseline to new count
- [x] 3.3 Run `make test` again to confirm baseline check passes
