## 1. Kernel primitives (Pass 1 — additive)

- [x] 1.1 Add `%initial-output-port` primitive in `runtime.lisp` — returns an output port wrapping `*standard-output*`; registered in `primitives.def`.
- [x] 1.2 Add `%initial-input-port` primitive in `runtime.lisp` — returns an input port wrapping `*standard-input*`; registered in `primitives.def`.
- [x] 1.3 Add `%display-to-port` primitive in `runtime.lisp` — requires explicit port argument; no fallback stream.
- [x] 1.4 Add `%write-to-port` primitive in `runtime.lisp` — requires explicit port argument.
- [x] 1.5 Add `%newline-to-port` primitive in `runtime.lisp` — requires explicit port argument.
- [x] 1.6 Add `%write-char-to-port` primitive in `runtime.lisp` — requires explicit port argument.
- [x] 1.7 Add `%write-string-to-port` primitive in `runtime.lisp` — requires explicit port argument.
- [x] 1.8 Register all five write primitives and two initial-port primitives in `primitives.def` with new stable IDs.

## 2. WASM kernel (Pass 1 — additive)

- [x] 2.1 Add WAT implementations of `%display-to-port`, `%write-to-port`, `%newline-to-port`, `%write-char-to-port`, `%write-string-to-port` in `wasm/runtime.wat` matching primitive IDs from 1.8.
- [x] 2.2 Add WAT implementations of `%initial-output-port` and `%initial-input-port` in `wasm/runtime.wat`.
- [x] 2.3 Run `make wasm` to rebuild `wasm/runtime.wasm`.

## 3. Prelude wrappers

- [x] 3.1 In `src/prelude.scm`, define `current-output-port` as `(make-parameter (%initial-output-port))`.
- [x] 3.2 In `src/prelude.scm`, define `current-input-port` as `(make-parameter (%initial-input-port))`.
- [x] 3.3 In `src/prelude.scm`, define `display` as an ECE procedure taking optional port, defaulting to `(current-output-port)`.
- [x] 3.4 In `src/prelude.scm`, define `write` as an ECE procedure taking optional port, defaulting to `(current-output-port)`.
- [x] 3.5 In `src/prelude.scm`, define `newline` as an ECE procedure taking optional port, defaulting to `(current-output-port)`.
- [x] 3.6 In `src/prelude.scm`, define `write-char` as an ECE procedure taking optional port, defaulting to `(current-output-port)`.
- [x] 3.7 In `src/prelude.scm`, define `write-string` as an ECE procedure taking optional port, defaulting to `(current-output-port)`.
- [x] 3.8 Add `with-output-to-string` macro in `src/prelude.scm` using `parameterize` + `open-output-string` + `get-output-string`.
- [x] 3.9 Add `with-input-from-string` macro in `src/prelude.scm` using `parameterize` + `open-input-string`.
- [x] 3.10 Add `with-output-to-port` macro in `src/prelude.scm` — rebinds `current-output-port` to a caller-supplied port for the body's dynamic extent.
- [x] 3.11 Add `with-input-from-port` macro in `src/prelude.scm` — rebinds `current-input-port` similarly.

## 4. Bootstrap — Pass 1

- [x] 4.1 Run `make bootstrap` with host primitives still present; verify it succeeds.
- [x] 4.2 Verify the regenerated `bootstrap/bootstrap.ecec` boots correctly and `(display "hi")` still works at the REPL (via the new ECE wrappers hitting `%display-to-port`).

## 5. Remove host primitives (Pass 2)

- [x] 5.1 Delete `ece-display` / `ece-write` / `ece-newline` / `ece-write-char` / `ece-write-string` from `src/runtime.lisp`.
- [x] 5.2 Delete the old `display` / `write` / `newline` / `write-char` / `write-string` entries from `primitives.def`.
- [x] 5.3 Delete `*current-output-port*` and `*current-input-port*` CL defvars and their accessor defuns in `src/runtime.lisp`.
- [x] 5.4 Audit `src/runtime.lisp` for any remaining references to the removed defvars; remove dead code.
- [x] 5.5 Remove the corresponding WAT implementations of the old `display` / `write` / `newline` / `write-char` / `write-string` primitives from `wasm/runtime.wat`.
- [x] 5.6 Run `make wasm` to rebuild `wasm/runtime.wasm` without old primitives.

## 6. Bootstrap — Pass 2

- [x] 6.1 Run `make bootstrap` again; verify clean bootstrap without the removed primitives.
- [x] 6.2 Commit updated `bootstrap/bootstrap.ecec`, `primitives.def`, `wasm/runtime.wasm`, generated `wasm/primitives.json`.

## 7. Tests

- [x] 7.1 Create `tests/ece/test-output-capture.scm` with scenarios covering the `output-capture` spec (capture single/multiple writes, write-in-readable-form, nested capture isolation, error-inside-body restores port).
- [x] 7.2 Add a scenario in `tests/ece/test-output-capture.scm` verifying `with-input-from-string` reads characters and structured data from the string.
- [x] 7.3 Add a scenario verifying `with-output-to-port` and `with-input-from-port` use caller-supplied ports.
- [x] 7.4 Add a scenario in `tests/ece/test-parameters.scm` (or a new file) verifying continuation escape out of `parameterize` restores `current-output-port`.
- [x] 7.5 Register new test file(s) in `tests/ece/run-all.scm` (and `run-cl.scm` / `run-wasm.scm` as appropriate).

## 8. Verification

- [x] 8.1 Run `make test-rove` — all passing (581 passed; pre-existing harness exit-code issue in rove integration unrelated).
- [x] 8.2 Run `make test-ece` — all passing (679 passed, including new output-capture tests).
- [x] 8.3 Run `make test-conformance` — no regressions (162 passed).
- [x] 8.4 Run `make test-wasm` — all passing (609 passed; WASM kernel in sync).
- [x] 8.5 Run `make test-web-apps` — sandbox/test-page smoke test passes (6 passed).
- [x] 8.6 Manually verify at `make repl`: `(parameterize ((current-output-port (open-output-string))) (display "x"))` does not emit "x" to stdout — verified via `ece:evaluate`.

## 9. Update test counts and artifacts

- [x] 9.1 Refresh `tests/test-counts.json` (cl-ece: 679, wasm-ece: 609, conformance: 162).
- [x] 9.2 Run `make fmt` — formatting applied; files are idempotent.

## 10. Incidental fixes (discovered during verification)

- [x] 10.1 Remove destructive `git checkout --` from `Makefile`'s `check-fmt` target — it was silently discarding unstaged working-tree changes when formatting diffs were detected.
