## 1. Implement string->number in ECE prelude

- [x] 1.1 Add `string->number`, `%parse-digits`, `%parse-frac` to "Derived predicates" section of `prelude.scm` (after `number->string`)
- [x] 1.2 Verify ordering: all dependencies (`char->integer`, `string-ref`, `string-length`, `char=?`) are available before the definition

## 2. Bootstrap pass 1 (with host still present)

- [x] 2.1 Run `make bootstrap` — generates new .ecec files with ECE `string->number`

## 3. Remove from CL host

- [x] 3.1 Remove `ece-boolean-p` function from `runtime.lisp`
- [x] 3.2 Remove `ece-string->number` function from `runtime.lisp`
- [x] 3.3 Remove `boolean?` and `string->number` entries from `*wrapper-primitives*` in `runtime.lisp`

## 4. Remove from WASM dispatch

- [x] 4.1 Remove ID 19 dispatch case (`boolean?`) from `$apply-primitive`
- [x] 4.2 Remove ID 29 dispatch case (`string->number`) from `$apply-primitive`
- [x] 4.3 Remove `$prim-string-to-number` and `$parse-float-after-dot` WAT functions
- [x] 4.4 Keep `$is-boolean` WAT function as internal helper (used by `$prim-write` and `$prim-equal`)

## 5. Update manifests

- [x] 5.1 Change IDs 19, 29 from `core` to `ece` in `primitives.def`
- [x] 5.2 Regenerate `wasm/primitives.json` via `bash scripts/gen-primitives-json.sh`

## 6. Bootstrap pass 2 and test

- [x] 6.1 Clear FASL cache and run `make bootstrap` pass 2
- [x] 6.2 Run CL test suite (`make test`) — all tests pass
- [x] 6.3 Build WASM (`make wasm`) and run WASM test suite (`make test-wasm`) — all tests pass
- [x] 6.4 Rebuild sandbox (`make sandbox`) and verify game loop demo works
