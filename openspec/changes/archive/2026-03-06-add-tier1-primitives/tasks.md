## 1. Primitives

- [x] 1.1 Add `error` primitive (direct mapping to `cl:error`)
- [x] 1.2 Add `assoc` and `member` primitives (direct CL mappings)
- [x] 1.3 Add `list-ref` and `list-tail` primitives (map to `nth` and `nthcdr`)
- [x] 1.4 Add string comparison primitives: `string=?`, `string<?`, `string>?` (map to CL `string=`, `string<`, `string>`)
- [x] 1.5 Export all new symbols from ECE package

## 2. Tests

- [x] 2.1 Add error tests (signal error, catchable by try-eval)
- [x] 2.2 Add assoc/member tests (found, not found, numeric/symbol keys)
- [x] 2.3 Add list-ref/list-tail tests (various indices)
- [x] 2.4 Add string comparison tests (equal, less than, greater than)
- [x] 2.5 Run all tests and verify pass
