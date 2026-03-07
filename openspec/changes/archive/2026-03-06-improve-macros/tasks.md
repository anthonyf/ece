## 1. Fix cond

- [x] 1.1 Rewrite `cond` to support multi-expression clause bodies (wrap in `begin`) and use quasiquote

## 2. Rewrite macros with quasiquote

- [x] 2.1 Rewrite `let` macro to use quasiquote
- [x] 2.2 Rewrite `let*` macro to use quasiquote
- [x] 2.3 Rewrite `and` macro to use quasiquote
- [x] 2.4 Rewrite `or` macro to use quasiquote
- [x] 2.5 Rewrite `when` and `unless` macros to use quasiquote

## 3. Tests

- [x] 3.1 Add test for multi-expression `cond` clause body
- [x] 3.2 Run all tests and verify pass
