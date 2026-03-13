## 1. Test Framework

- [x] 1.1 Create `tests/ece/test-framework.scm` with `test`, `assert-equal`, `assert-true`, `assert-error`, and `run-tests`
- [x] 1.2 Verify framework works: register a few tests, run them, confirm pass/fail counts and error isolation

## 2. Test Files — Data Types & Operations

- [x] 2.1 Create `tests/ece/test-arithmetic.scm` — +, -, *, /, modulo, abs, min, max, numeric comparisons
- [x] 2.2 Create `tests/ece/test-lists.scm` — cons, car, cdr, list, append, reverse, length, list-ref, list-tail, assoc, predicates
- [x] 2.3 Create `tests/ece/test-strings.scm` — string-length, string-ref, substring, string-append, comparisons, interpolation
- [x] 2.4 Create `tests/ece/test-vectors.scm` — make-vector, vector, vector-ref, vector-set!, vector-length, vector->list
- [x] 2.5 Create `tests/ece/test-hash-tables.scm` — make-hash-table, ref, set!, delete!, keys, values, literals
- [x] 2.6 Create `tests/ece/test-types.scm` — type predicates, eq?, eqv?, equal?, boolean operations

## 3. Test Files — Control Flow & Binding

- [x] 3.1 Create `tests/ece/test-control-flow.scm` — if, cond, case, and, or, when, unless, do
- [x] 3.2 Create `tests/ece/test-closures.scm` — lambda, let, let*, letrec, named let, closure capture
- [x] 3.3 Create `tests/ece/test-macros.scm` — define-macro, quasiquote, macro shadowing
- [x] 3.4 Create `tests/ece/test-tco.scm` — TCO across if, begin, cond, and, or, when, unless, let, let*, named let (100k+ iterations)

## 4. Test Files — Advanced Features

- [x] 4.1 Create `tests/ece/test-callcc.scm` — call/cc non-local exit, coroutine patterns, continuation invocation
- [x] 4.2 Create `tests/ece/test-higher-order.scm` — map, filter, reduce, for-each, compose, any, every
- [x] 4.3 Create `tests/ece/test-records.scm` — define-record constructor, predicate, accessors
- [x] 4.4 Create `tests/ece/test-errors.scm` — error signaling, assert
- [x] 4.5 Create `tests/ece/test-parameters.scm` — make-parameter, parameterize

## 5. Runner & Makefile

- [x] 5.1 Create `tests/ece/run-all.scm` — loads framework + all test files, calls run-tests
- [x] 5.2 Add `test-ece` target to Makefile that runs `run-all.scm` via ECE and exits with 0/1
- [x] 5.3 Run `make test-ece` end-to-end and verify all tests pass
