## 1. Add gensym primitive

- [x] 1.1 Register `gensym` as a primitive procedure (delegate to CL's `gensym`)
- [x] 1.2 Export `gensym` from the ECE package

## 2. Fix or macro

- [x] 2.1 Rewrite `or` macro to use `let` + `gensym` to avoid double evaluation

## 3. Tests

- [x] 3.1 Add tests for `gensym` (returns symbol, returns unique symbols)
- [x] 3.2 Add regression test for `or` double-evaluation bug
- [x] 3.3 Run tests and verify all pass
