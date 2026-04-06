## 1. Spike — audit risks before restructuring

- [x] 1.1 Grep `tests/ece/test-*.scm` for cross-file references (helper functions/vars defined in one file used in another). Record findings.
- [x] 1.2 Identify the set of files that load successfully in a **fresh env** via `bin/ece-test single-file.scm`. Record any that fail.
- [x] 1.3 Run `test-compilation-units.scm`, `test-serialization.scm`, `test-source-locations.scm` individually via `bin/ece-test` and record pass/fail under per-file isolation.
- [x] 1.4 Run `test-output-capture.scm` and `test-parameters.scm` individually — verify they don't conflict with ece-test's own `parameterize` on `current-output-port`.
- [x] 1.5 From findings, list any files that need rewriting before they can be moved into the new layout. Plan mitigations (helper extraction, state reset, etc.).

## 2. Rename and consolidate the framework file

- [x] 2.1 `git mv src/test-lib.scm src/ece-unit.scm`.
- [x] 2.2 Update references: `Makefile` install target, `scripts/build-ece-binary.lisp` `compile-system` arg list, any grep for "test-lib" in scripts.
- [x] 2.3 Extend `ece-unit.scm`: add `collected` count to state; update `run-tests` return tuple to `(collected ran passes failures failure-messages per-test-output)`. Thread a filter-matcher arg through.
- [x] 2.4 Delete `tests/ece/test-framework.scm`.
- [x] 2.5 Update `src/ece-test.scm` to consume the new `run-tests` tuple (collected/ran extraction).

## 3. Add --filter PATTERN to ece-test

- [x] 3.1 Extend `parse-test-args` in `src/ece-test.scm` to recognize `--filter PATTERN` (repeatable; collect into a list of patterns).
- [x] 3.2 Implement `make-substring-matcher` in `src/ece-unit.scm` (or `src/sdk-lib.scm`): takes a list of patterns, returns a `(name) -> boolean` predicate. Empty list = match-all.
- [x] 3.3 Wire the matcher into `run-one-test-file` / `run-tests` so only matching tests run.
- [x] 3.4 Update `print-file-results` and the summary to show `collected N, ran M, passed X, failed Y`.
- [x] 3.5 Update `ece-test-usage` help text to document `--filter`.

## 4. Hygiene — zero-tests-collected exit

- [x] 4.1 Track the total `collected` count across all test files in `ece-test-main`.
- [x] 4.2 If `collected == 0` across all loaded files, print an error to `stderr` and exit `2`.
- [x] 4.3 Confirm existing "path does not exist" error path still exits `2` with its existing message.

## 5. Restructure tests/ece/

- [x] 5.1 Create `tests/ece/common/` and `tests/ece/cl-only/` directories.
- [x] 5.2 Move pure-ECE tests into `common/` (arithmetic, lists, strings, vectors, hash-tables, control-flow, closures, macros, syntax-rules, tco, callcc, callcc-tco, higher-order, records, errors, parameters, mutation, advanced-continuations, misc, eval-string, file-io, roundtrip, cross-space, dynamic-wind, guard, error-messages, output-capture, types).
- [x] 5.3 Move CL-only tests into `cl-only/` (compilation-units, serialization, source-locations, ece-main-args, ece-test-runner).
- [x] 5.4 Extract any cross-file helpers flagged by task 1.1 into `tests/ece/common/helpers-*.scm` files (prefix to avoid `test-*.scm` pattern match).
- [x] 5.5 Update any in-file `(load "...")` statements to reference new paths.

## 6. Delete orchestration scripts

- [x] 6.1 Delete `tests/ece/run-all.scm`.
- [x] 6.2 Delete `tests/ece/run-common.scm`.
- [x] 6.3 Delete `tests/ece/run-cl.scm`.
- [x] 6.4 Delete `tests/ece/run-wasm.scm`.

## 7. Update Makefile

- [x] 7.1 Change `test-ece` target to invoke `bin/ece-test tests/ece/common tests/ece/cl-only`.
- [x] 7.2 Change `test-wasm` target: `WASM_TEST_SRCS := src/ece-unit.scm $(wildcard tests/ece/common/test-*.scm) wasm/wasm-test-runner.scm`.
- [x] 7.3 Update the `test` aggregator target to remove `check-test-counts` from the dependency list.
- [x] 7.4 Delete the `check-test-counts` target.
- [x] 7.5 Delete the `update-test-counts` target.
- [x] 7.6 Ensure `test-ece` depends on `ece` (so `bin/ece` exists).

## 8. Update WASM test runner

- [x] 8.1 Update `wasm/wasm-test-runner.scm` to call `run-tests` from `ece-unit.scm` (not `test-framework.scm`).
- [x] 8.2 Update `wasm-test-runner.scm` to format the tuple result (collected/ran/passed/failed) for output parsing by `wasm/test.js`.
- [x] 8.3 Verify `wasm/test.js` greps still match the new output format ("N passed, N failed").

## 9. Delete baseline-count tooling

- [x] 9.1 Delete `tests/test-counts.json`.
- [x] 9.2 Delete `scripts/check-test-counts.sh`.
- [x] 9.3 Grep for any remaining references to `check-test-counts` or `update-test-counts` in `.github/`, `scripts/`, `README.md`.

## 10. Un-gimp integration tests

- [x] 10.1 Rewrite `tests/ece/cl-only/test-ece-test-runner.scm` to directly test `run-one-test-file` (previously blocked by dual-framework conflict).
- [x] 10.2 Add tests covering the `--filter PATTERN` behavior (single filter, multiple filters, empty filter, no matches).
- [x] 10.3 Add a test covering exit-2-on-zero-collected.

## 11. Install path

- [x] 11.1 Verify `make install` copies `src/ece-unit.scm` (renamed) to `$PREFIX/share/ece/ece-unit.scm`.
- [x] 11.2 Rebuild `bin/ece` via `make ece` and confirm `ece-main.ecec` bundles `src/ece-unit.scm`.

## 12. Verification

- [x] 12.1 `make test-rove` — all passing, including integration tests from §10.
- [x] 12.2 `make test-ece` — via new `bin/ece-test` path; report counts match sum of common + cl-only.
- [x] 12.3 `make test-conformance` — unchanged, passes.
- [x] 12.4 `make test-wasm` — via new glob path, all passing, counts match common/ size.
- [x] 12.5 `make test-web-apps` — passes.
- [x] 12.6 `make test-golden` — passes.
- [x] 12.7 `make test` (full aggregator) — passes cleanly, no references to missing targets.

## 13. Documentation

- [x] 13.1 Update README's testing section: `ece-test --filter`, new directory layout, dropped baseline counts.
- [x] 13.2 Update `tests/ece/README.md` (if present) to reflect common/ vs cl-only/ split.
- [x] 13.3 Run `make check-fmt`.
