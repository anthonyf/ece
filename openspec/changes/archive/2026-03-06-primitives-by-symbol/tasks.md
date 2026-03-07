## 1. Refactor primitive storage

- [x] 1.1 Change `*primitive-procedure-objects*` to store symbols instead of `(symbol-function ...)`
- [x] 1.2 Change dolist registrations to use quoted symbols instead of `#'function` references
- [x] 1.3 Change `:primitive-apply` to resolve symbol via `symbol-function` at call time

## 2. Verify

- [x] 2.1 Run all tests and verify pass (zero behavior change)
