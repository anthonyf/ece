## 1. Add string output port primitives

- [x] 1.1 Add `open-output-string` (ID 175) and `get-output-string` (ID 176) to `primitives.def` as core primitives
- [x] 1.2 Implement `ece-open-output-string` and `ece-get-output-string` in `src/runtime.lisp`
- [x] 1.3 Implement `$open-output-string` and `$get-output-string` in `wasm/runtime.wat`

## 2. Port-based serialization in prelude.scm

- [x] 2.1 Rewrite `ser`, `ser-compound`, `ser-entry`, `ser-pair` to use `(display ... port)` instead of returning strings
- [x] 2.2 Wrap top-level `serialize-value` with `(open-output-string)` / `(get-output-string)`
- [x] 2.3 Fix `deser-pair` to force left-to-right evaluation (car before cdr) so `%ser/def` stores before `%ser/ref` reads
- [x] 2.4 Replace `try-eval` with `guard` in test framework (avoid unnecessary compilation per test)
- [x] 2.5 Rebuild bootstrap (`make bootstrap`)

## 3. Test suite verification

- [x] 3.1 Run `make test` (Rove) — all tests pass (551 passed, 0 failed)
- [x] 3.2 Run `make test-wasm` — all tests pass (527 passed, 0 failed)
- [ ] 3.3 Run `make test-ece` — completes without OOM, zero failures
  - **Blocked**: Continuations captured inside function calls produce enormous serialized output (>2GB for a trivial continuation). The O(n²) string-append is fixed, but the serializer traverses the full runtime state through the continuation's stack. This needs a separate fix (serialization depth limit or stack trimming).
