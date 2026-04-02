## Why

ECE has two runtimes (CL and WASM) that execute the same compiled bytecode, but testing infrastructure has drifted: separate test manifests, platform-specific assertions baked into shared tests, conformance failures silently ignored, and no regression gates. Recent PRs (#73–#82) have been a game of whack-a-mole — fixing one thing surfaces bugs elsewhere. A stable foundation is needed before building the native compiler.

## What Changes

- **Make conformance tests blocking in CI** — remove `continue-on-error: true` from the conformance step. Suite is 157/157 passing, so this is free.
- **Fix representation-leaking test assertions** — replace `(pair? k)` / `(car k)` with `(continuation? k)` in test-callcc-tco.scm and test-serialization.scm. CL continuations are tagged lists; WASM continuations are opaque structs. Tests must use abstract predicates.
- **Fix WASM tail-position call/cc TCO** — the WASM runtime hangs on tail-position call/cc loops (confirmed: 10K iteration test never completes). The compiler's tail-position call/cc path generates valid instructions but the WASM dispatch loop doesn't handle the pattern correctly.
- **Unify test manifests** — replace the dual system (Makefile `WASM_TEST_SRCS` + `run-common.scm`) with a single test list. Platform-specific tests use `(when (platform-has? ...)` guards to self-skip. No more manual curation of which files run where.
- **Migrate excluded test files to cross-platform** — triage the 4 files excluded from WASM: `test-callcc-tco.scm` (needs assertion fix + WASM TCO fix), `test-errors.scm` and `test-error-messages.scm` (need `guard`-based alternatives to `assert-error` which depends on `try-eval`), `test-file-io.scm` (already has `platform-has?` guards).
- **Add test-count regression check in CI** — fail the build if the number of passing tests drops, catching accidental test removal or silent breakage.

## Capabilities

### New Capabilities
- `test-manifest-unification`: Single source of truth for which test files run on all platforms, replacing dual WASM_TEST_SRCS + run-common.scm system
- `test-count-regression`: CI check that fails if the number of passing tests decreases compared to a checked-in baseline
- `cross-platform-assert-error`: Guard-based `assert-error` alternative that works on both CL and WASM (no `try-eval` dependency)

### Modified Capabilities
- `callcc-tail-tco`: WASM runtime must handle the tail-position call/cc instruction pattern (currently CL-only)
- `conformance-test-runner`: Make conformance failures blocking in CI instead of informational
- `ece-test-framework`: Tests must use abstract predicates (`continuation?`) not representation-specific checks (`pair?`/`car`)

## Impact

- `.github/workflows/test.yml` — CI pipeline changes (blocking conformance, test-count check)
- `wasm/runtime.wat` — WASM instruction dispatch fix for tail-position call/cc
- `tests/ece/test-callcc-tco.scm` — assertion fixes
- `tests/ece/test-serialization.scm` — assertion fixes
- `tests/ece/test-errors.scm` — migrate from `assert-error`/`try-eval` to guard-based approach
- `tests/ece/test-error-messages.scm` — same migration
- `tests/ece/test-framework.scm` — new `assert-error` implementation using `guard`
- `tests/ece/run-common.scm` — becomes the single test manifest
- `Makefile` — `WASM_TEST_SRCS` derived from or replaced by the unified manifest
