## 1. Implement in ECE prelude

- [x] 1.1 Add `char=?` and `char<?` to "Character predicates" section of `prelude.scm`
- [x] 1.2 Add `string=?`, `string<?`, `string>?` to "String operations" section (after char predicates, before existing string functions)
- [x] 1.3 Add `vector->list` and `list->vector` after "Higher-order functions" section (needs `length`)
- [x] 1.4 Verify ordering: char comparisons before string comparisons; all before any code that calls them

## 2. Bootstrap pass 1 (with host still present)

- [x] 2.1 Run `make bootstrap` — generates new .ecec files with ECE definitions

## 3. Remove from CL host

- [x] 3.1 Remove `ece-char=?`, `ece-char<?` functions from `runtime.lisp`
- [x] 3.2 Remove `ece-string=?`, `ece-string<?`, `ece-string>?` functions from `runtime.lisp`
- [x] 3.3 Remove `ece-vector->list`, `ece-list->vector` functions from `runtime.lisp`
- [x] 3.4 Remove all 7 entries from `*wrapper-primitives*` in `runtime.lisp`

## 4. Remove from WASM dispatch

- [x] 4.1 Remove ID 33, 34, 35 dispatch cases (string comparisons) from `$apply-primitive`
- [x] 4.2 Remove ID 45, 46 dispatch cases (char comparisons) from `$apply-primitive`
- [x] 4.3 Remove ID 55, 56 dispatch cases (vector conversions) from `$apply-primitive`
- [x] 4.4 Keep WAT functions `$prim-string-eq`, `$prim-string-lt`, `$prim-string-gt`, `$prim-list-to-vector` as internal helpers

## 5. Update manifests

- [x] 5.1 Change IDs 33, 34, 35, 45, 46, 55, 56 from `core` to `ece` in `primitives.def`
- [x] 5.2 Regenerate `wasm/primitives.json` via `bash scripts/gen-primitives-json.sh`

## 6. Bootstrap pass 2 and test

- [x] 6.1 Clear FASL cache and run `make bootstrap` pass 2
- [x] 6.2 Run CL test suite (`make test`) — all tests pass
- [x] 6.3 Build WASM (`make wasm`) and run WASM test suite (`make test-wasm`) — all tests pass
- [x] 6.4 Rebuild sandbox (`make sandbox`) and verify game loop demo works
