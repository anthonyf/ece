## 1. Add reverse primitive

- [x] 1.1 Add `reverse` to primitive procedure names/objects (wrapping `cl:reverse`)
- [x] 1.2 Export `reverse` from the ECE package

## 2. Rewrite map and filter

- [x] 2.1 Rewrite `map` using named let with accumulator + `reverse`
- [x] 2.2 Rewrite `filter` using named let with accumulator + `reverse`

## 3. Tests

- [x] 3.1 Add tests for `reverse` (list, empty, single element)
- [x] 3.2 Add large-list TCO test for `map` (100,000 elements)
- [x] 3.3 Add large-list TCO test for `filter` (100,000 elements)
- [x] 3.4 Run all tests and verify pass
