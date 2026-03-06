## 1. Modify environment binding

- [x] 1.1 Update `extend-environment` to handle dotted parameter lists: when `vars` is a dotted pair, bind the rest parameter name to remaining `vals`
- [x] 1.2 Handle rest-only parameters (symbol instead of list): when `vars` is a symbol, bind it to the entire `vals` list

## 2. Tests

- [x] 2.1 Add tests for rest parameters: extra args captured, no extra args gives nil, mixed fixed and rest, rest-only parameter
- [x] 2.2 Add tests for define shorthand with rest parameters: `(define (f x . rest) ...)` and `(define (f . args) ...)`
