## Why

ECE ships two parallel test-authoring implementations today: `src/test-lib.scm` (user-facing, parameter-based state, per-test output capture — shipped in `share/ece/`) and `tests/ece/test-framework.scm` (ECE's own tests, global-mutation state). They have the same API (`test`, `assert-equal`, ...) but different internals, so loading both in one image is a conflict. This blocked the `ece-sdk-toolchain` change from writing an integration test for `run-one-test-file`.

Meanwhile `ece-test` is user-facing tooling for running tests, but ECE's own test suite doesn't use it — `make test-ece` has its own ad-hoc orchestration via `run-all.scm` / `run-common.scm` / `run-cl.scm`. Dogfooding `ece-test` on ECE's 750+ tests removes the duplicate framework, exercises the runner on a real-world suite, and makes ECE's own tests the canonical example of the user-facing API.

## What Changes

- **Unify test framework:** rename `src/test-lib.scm` → `src/ece-unit.scm`, absorbing the functionality in `tests/ece/test-framework.scm`. One framework, one API, user-facing.
- **Restructure test layout:** move `tests/ece/test-*.scm` into `tests/ece/common/` (runs on any runtime) and `tests/ece/cl-only/` (needs CL primitives).
- **Dogfood `ece-test`:** `make test-ece` now runs `bin/ece-test tests/ece/common tests/ece/cl-only` instead of orchestrating via `run-all.scm` etc.
- **`ece-test --filter PATTERN`:** substring match on test names, to run a subset during development.
- **Runner hygiene:** `ece-test` reports `collected / ran / passed / failed` counts; exits `2` if zero tests are collected (catches bad paths and rename-outs without a baseline file).
- **Drop test-counts baseline:** delete `tests/test-counts.json`, `scripts/check-test-counts.sh`, and the `update-test-counts` Makefile target. Runner exit codes + "0 failed" are enough (pytest/Jest/Go/Rust model).
- **WASM path updates:** the WASM test bundle globs `tests/ece/common/test-*.scm` and loads `src/ece-unit.scm` in place of the deleted `test-framework.scm`.
- **BREAKING:** delete `tests/ece/test-framework.scm`, `tests/ece/run-all.scm`, `tests/ece/run-common.scm`, `tests/ece/run-cl.scm`, `tests/ece/run-wasm.scm`. These are absorbed into the directory-based discovery model.
- **BREAKING:** `test-counts.json` and its tooling removed. CI relies on runner exit codes.

## Capabilities

### New Capabilities

None — this change consolidates and refactors existing capabilities.

### Modified Capabilities

- `ece-test-framework`: renamed to live in `src/ece-unit.scm`; requirements about the `test` registry, `assert-*` forms, and `run-tests` still hold. The framework now uses parameter-based state instead of global mutation (already the case in `src/test-lib.scm` post-`ece-sdk-toolchain`).
- `ece-test-suite`: file layout changes — tests move into `common/` and `cl-only/` subdirectories. `run-all.scm` single entry point removed. Makefile integration now uses `bin/ece-test`.
- `ece-test-runner`: adds `--filter PATTERN` flag; adds `collected` count alongside `passed`/`failed`; adds exit code `2` on zero tests collected.
- `makefile`: `test-ece` target invokes `bin/ece-test` directly; `test-wasm` globs `tests/ece/common/` for the bundle; `update-test-counts` and `check-test-counts` targets removed.

## Impact

- **Affected code:**
  - Renamed: `src/test-lib.scm` → `src/ece-unit.scm`.
  - Modified: `src/ece-test.scm` (filter flag, hygiene counts), `src/ece-main.scm` (argv parsing).
  - Restructured: `tests/ece/*.scm` split across `tests/ece/common/` and `tests/ece/cl-only/`.
  - Deleted: `tests/ece/test-framework.scm`, `tests/ece/run-all.scm`, `tests/ece/run-common.scm`, `tests/ece/run-cl.scm`, `tests/ece/run-wasm.scm`, `tests/test-counts.json`, `scripts/check-test-counts.sh`.
  - Modified: `Makefile` (test-ece, test-wasm, remove update-test-counts + check-test-counts), `wasm/test.js` or equivalent bundler, `scripts/build-ece-binary.lisp` (references to `test-lib.scm`).
  - Modified: CI workflow if it invokes `check-test-counts` directly.
- **Dependencies:** none new. Depends on `ece-sdk-toolchain` (shipped) for `bin/ece-test`, `make ece`, argv[0] dispatch.
- **Dev workflow:** contributors run `bin/ece-test tests/ece/common/test-strings.scm` for a single file, `bin/ece-test --filter string tests/ece/common` to filter, `bin/ece-test tests/ece/common tests/ece/cl-only` for the full suite. The runner output format changes (new `collected/ran` counts) — anything parsing the output needs updating.
- **Tests:** the self-hosted `test-ece-test-runner.scm` tests can be un-gimped (currently tests only pure helpers because the dual-framework conflict prevented direct testing of `run-one-test-file`).
- **Risks:** (1) cross-file test dependencies — if `test-foo.scm` implicitly depends on a helper defined in `test-bar.scm`, per-file isolation will break it. (2) `test-output-capture.scm` and `test-parameters.scm` may interact with `ece-test`'s own `parameterize` on `current-output-port`. (3) `test-compilation-units.scm`, `test-serialization.scm`, `test-source-locations.scm` exercise global compiler state and may not tolerate per-file isolation cleanly. All three risks need spike investigation before full conversion.
