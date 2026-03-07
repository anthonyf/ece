## 1. TCO verification tests

- [x] 1.1 Add test for tail call in `if` consequent/alternative (1M iterations)
- [x] 1.2 Add test for tail call in `begin` last expression (1M iterations)
- [x] 1.3 Add test for tail call in `cond` clause body (1M iterations)
- [x] 1.4 Add test for tail call in `and`/`or` last argument (1M iterations)
- [x] 1.5 Add test for tail call in `when`/`unless` body (1M iterations)
- [x] 1.6 Add test for tail call in `let`/`let*` body (1M iterations)

## 2. Named let

- [x] 2.1 Modify `let` macro to detect named form and expand to `(begin (define (name params...) body...) (name inits...))`
- [x] 2.2 Add tests for named let: counting loop, list building, tail recursion (1M iterations), regular let still works

## 3. Verify

- [x] 3.1 Run all tests and verify pass
