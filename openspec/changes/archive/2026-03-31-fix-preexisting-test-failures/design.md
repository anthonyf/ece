## Context

`make test-ece` runs `run-all.scm` which loads all tests (common + CL-only) and calls `(run-tests)`. This OOMs even with 8GB heap. The CL-only tests include `test-serialization.scm` which serializes compiled procedures. When run inside `run-tests` → `try-eval` → nested `mc-compile-and-go`, the compiled procedure's environment chain is much deeper than when run standalone, and `serialize-value` uses recursive `string-append` which is O(n²) in memory for deep structures.

Separately, `with-output-to-file` and `with-input-from-file` call `apply-primitive-procedure` on thunks, but user-supplied thunks are compiled procedures, not primitives. This causes a type error that `try-eval` silently catches.

`test-roundtrip.scm` (23 tests) is only in WASM_TEST_SRCS, not in `run-common.scm`.

## Goals / Non-Goals

**Goals:**
- `make test-ece` completes without OOM
- `with-output-to-file` / `with-input-from-file` work with compiled procedure thunks
- `test-roundtrip.scm` runs in the CL test suite
- All tests pass with zero failures and zero silent skips

**Non-Goals:**
- Rewriting the serialization format
- Optimizing serialization performance beyond fixing the O(n²) issue
- Adding new serialization capabilities

## Decisions

### 1. Port-based serialization instead of string-append

**Decision:** Replace `serialize-value`'s recursive `string-append` approach with writing to an output string port, then extracting the final string.

**Rationale:** The current approach builds result strings bottom-up via `string-append`. Each call allocates a new string copying all previous content, creating O(n²) total allocation for a chain of n objects. A port-based approach writes each token once to a resizable buffer — O(n) total.

**Implementation:** Add a `port` parameter to the internal `ser` and `ser-compound` helpers. They call `display` / `write-char` to the port instead of returning strings. The top-level `serialize-value` wraps the call in `(open-output-string)` and returns `(get-output-string port)`.

**Alternative considered:** Limiting env chain depth with a max-depth cutoff. Rejected because it changes semantization semantics and could lose data needed for deserialization.

### 2. Use apply-ece-procedure for scoped port thunks

**Decision:** Change `ece-with-input-from-file` and `ece-with-output-to-file` to call `apply-ece-procedure` instead of `apply-primitive-procedure`.

**Rationale:** `apply-ece-procedure` already handles both primitives and compiled procedures (it dispatches via `compiled-procedure-p`). This matches the pattern used by `call-with-input-file` and `call-with-output-file` on the adjacent lines (945-955) which already work correctly.

### 3. Add test-roundtrip.scm to run-common.scm

**Decision:** Add `(load "tests/ece/test-roundtrip.scm")` to `run-common.scm` alongside other comprehensive coverage tests.

**Rationale:** These tests are platform-independent (they test serialize-value/deserialize-value roundtrips). They already run on WASM and should also run on CL.

## Risks / Trade-offs

- **[Port-based serialization requires `open-output-string` / `get-output-string`]** → These are already available as ECE primitives. The `write-to-string` function in prelude.scm already uses this pattern.
- **[Serialization output format unchanged]** → The port-based approach writes the same tokens in the same order, just via `display` instead of `string-append`. Deserialization is unaffected.
- **[Additional tests may surface new issues]** → If `test-roundtrip.scm` reveals CL-specific failures, they should be fixed as part of this change.
