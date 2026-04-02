## 1. Fix %env-frame? predicate

- [x] 1.1 Change `ece-%env-frame-p` in `runtime.lisp` from `(consp x) ∧ ¬(symbolp (car x))` to `(vectorp x)`
- [x] 1.2 Update `ece-%env-frame-names` to return nil for vector frames (no names)
- [x] 1.3 Update `ece-%env-frame-vals` to always coerce vector to list (remove cons-pair path)
- [x] 1.4 Run rove tests to verify no regressions from predicate change

## 2. Remove named-list frame path from extend-environment

- [x] 2.1 Remove the 3-arg (named-list) branch from `extend-environment`
- [x] 2.2 Remove `make-frame` and `frame-variables`/`frame-values` helpers if now unused
- [x] 2.3 Remove the `scan-frame` named-list path from `lookup-variable-value`
- [x] 2.4 Remove the named-list path from `set-variable-value!`
- [x] 2.5 Run all tests (`make test`) to verify nothing uses named-list frames

## 3. Fix serializer

- [x] 3.1 Remove the `(%env-frame? obj)` branch from `scan` in `serialize-value` (prelude.scm)
- [x] 3.2 Remove the `(%env-frame? obj)` branch from `ser-compound` in `serialize-value`
- [x] 3.3 Verify the `(%hash-frame? obj)` and `(eq? obj global-frame)` checks still catch the global env
- [x] 3.4 Test: `serialize-value` on a continuation captured via `eval-string` completes without OOM
- [x] 3.5 Test: round-trip continuation serialization produces correct output (< 1KB for trivial case)

## 4. Re-enable serialization tests in CI

- [x] 4.1 Change `test-ece` Makefile target back to `run-all.scm` (includes test-serialization.scm)
- [x] 4.2 Run `make test` locally — all suites pass including serialization round-trips
- [ ] 4.3 Verify CI passes with serialization tests included
