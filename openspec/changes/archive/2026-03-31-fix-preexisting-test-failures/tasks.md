## 1. Fix scoped port redirection

- [x] 1.1 Change `ece-with-input-from-file` to use `apply-ece-procedure` instead of `apply-primitive-procedure` in `src/runtime.lisp`
- [x] 1.2 Change `ece-with-output-to-file` to use `apply-ece-procedure` instead of `apply-primitive-procedure` in `src/runtime.lisp`
- [x] 1.3 Verify `test-file-io.scm` with-output-to-file and with-input-from-file tests pass (no longer silently skipped)

## 2. Port-based serialization

- [x] 2.1 Add `port` parameter to `ser`, `ser-compound`, `ser-entry`, `ser-pair` helpers in `serialize-value` (src/prelude.scm)
- [x] 2.2 Replace all `string-append` return values with `display` / `write-string-to-port` calls to the port
- [x] 2.3 Wrap top-level `serialize-value` with `open-output-string` / `get-output-string`
- [x] 2.4 Verify `test-serialization.scm` passes when run standalone
- [x] 2.5 Verify `test-roundtrip.scm` passes when run standalone

## 3. Test suite integration

- [x] 3.1 Add `(load "tests/ece/test-roundtrip.scm")` to `tests/ece/run-common.scm`
- [x] 3.2 Rebuild bootstrap (`make bootstrap`)
- [x] 3.3 Run `make test` (Rove) — all tests pass
- [x] 3.4 Run `make test-wasm` — all tests pass
- [ ] 3.5 Run `make test-ece` — completes without OOM, zero failures (deferred: OOM is pre-existing, needs separate proposal)
