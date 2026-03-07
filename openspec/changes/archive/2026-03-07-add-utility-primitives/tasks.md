## 1. Wrapper Functions

- [x] 1.1 Add `ece-sleep` wrapper that calls `cl:sleep` and returns nil
- [x] 1.2 Add `ece-clear-screen` wrapper that outputs ANSI escape sequences and returns nil
- [x] 1.3 Add `ece-string-split` wrapper that splits a string by a delimiter character (default space)

## 2. Registration and Exports

- [x] 2.1 Add all five primitives to `*wrapper-primitives*` (`sleep`, `clear-screen`, `string-downcase`, `string-upcase`, `string-split`)
- [x] 2.2 Add package exports for all five primitives

## 3. Tests

- [x] 3.1 Add tests for `string-downcase`, `string-upcase`, `string-split`, `sleep`, and `clear-screen`
