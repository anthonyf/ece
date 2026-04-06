## Context

12 tests are commented out across 3 test files, and the `make test-rove` target crashes after all tests pass due to a rove API mismatch. The disabled tests cover serialization (7), compilation units (2), and miscellaneous predicates (3). All actual test assertions pass when run — the issues are in infrastructure, serializer gaps, and CL/ECE boundary mismatches.

Key code locations:
- Serializer: `src/prelude.scm` lines 947-1133 (`serialize-value`)
- Test isolation: `src/ece-unit.scm` line 172 (`parameterize` wrapping `current-output-port`)
- Keyword primitive: `src/runtime.lisp` line 475 (`ece-keyword?` → CL `keywordp`)
- Platform-has primitive: `src/runtime.lisp` lines 1203-1209 (returns CL `nil` not ECE `#f`)
- Compilation units: `src/compilation-unit.scm` lines 79-83 (`write-compiled-unit`)
- Rove runner: `Makefile` line 92

## Goals / Non-Goals

**Goals:**
- All 12 commented-out tests uncommented and passing
- `make test` exits cleanly (all targets return 0)
- Fixes are minimal and localized — no architectural changes

**Non-Goals:**
- Full hash-table serialization overhaul (just enough for round-trip)
- Rewriting the test runner's isolation model
- ~~Fixing WASM `keyword?`~~ (implemented: checks `|:` prefix from CL pipe-escaping)
- Making `parameterize` frames fully serializable in the general case

## Decisions

### 1. Rove runner: enumerate suites explicitly

The Makefile calls `rove/core/suite::suite-stats` which doesn't exist. Use `CALL-WITH-SUITE` with `ALL-SUITES`/`RUN-SUITE` to enumerate and execute each discovered suite explicitly.

**Alternative considered:** Use `rove:run`. Rejected — it doesn't discover suites from FASL-cached files. Parsing test output with grep was also rejected as fragile.

### 2. `keyword?`: ECE-native check on CL side

Change `ece-keyword?` in `runtime.lisp` to check whether `x` is a symbol whose name starts with `":"`, rather than using CL's `keywordp`.

```
(defun ece-keyword? (x)
  (scheme-bool (and (symbolp x)
                    (let ((name (symbol-name x)))
                      (and (> (length name) 1)
                           (char= (char name 0) #\:))))))
```

**Alternative considered:** Implement in ECE prelude. Rejected — `keyword?` is already a CL primitive (id 137), changing just the implementation is less disruptive than adding a prelude override.

### 3. `platform-has?`: Return ECE `#f` instead of CL `nil`

The CL implementation returns `'nil` for unknown primitives. CL `nil` maps to ECE `()` (empty list), which is truthy in Scheme. Change the false branch to return the ECE false value (`*ece-false*` or equivalent).

### 4. Hash table serialization: add `hash-table?` predicate check

`serialize-value` already handles hash tables represented as tagged pairs `(:hash-table ...)`, but CL native hash tables (created by `make-hash-table`) fall through to the opaque fallback. Add a `(hash-table? obj)` check before the opaque fallback that serializes using the existing `(%ser/hash-table ...)` format with `hash-keys`/`hash-ref`.

The serializer at line 1053 checks `(and (pair? obj) (eq? (car obj) :hash-table))` — this is the tagged-pair representation. Real CL hash tables are CL objects, not tagged pairs. Need to add a branch that detects actual hash-table objects and emits the same `(%ser/hash-table ...)` output.

### 5. Continuation serialization under `parameterize`: skip non-serializable wind frames

The `parameterize` macro uses `dynamic-wind` to save/restore parameter values. The continuation's `winds` field captures these frames, which contain CL port objects and closures that can't be serialized.

**Approach:** In the serializer's continuation handler (lines 1070-1074), filter the winds list to exclude frames that contain non-serializable objects. Emit a sentinel `(%ser/wind-stripped)` for stripped frames so deserialization knows they were removed.

**Alternative considered:** Run serialization tests without `parameterize` isolation. Rejected — the tests should work under the same conditions as real code. The serializer should be robust to encountering non-serializable wind frames.

**Alternative considered:** Make all wind frame contents serializable. Rejected — CL port objects and native closures fundamentally can't be serialized to s-expressions.

### 6. `write-compiled-unit` label scoping: needs investigation

The test comment says "write-compiled-unit references a label that isn't registered in the current space." The `rename-labels` function is currently a no-op (identity). The issue likely relates to how labels from a `compile-file` space interact with the caller's space.

**Approach:** Investigate during implementation. The test comment mentions a workaround: "define inline, call rename-labels then write-flat-instructions." This suggests the fix may involve ensuring `write-compiled-unit` operates on a self-contained instruction sequence rather than resolving labels against the current execution space. Mark as investigate-during-implementation.

## Risks / Trade-offs

- **Wind frame stripping** — Stripping non-serializable wind frames means restored continuations won't re-establish those `dynamic-wind` guards. This is acceptable for serialization (you can't serialize a port anyway), but the sentinel should make the loss explicit. → Mitigation: document in serialization that wind frames with non-serializable content are stripped.

- **`write-compiled-unit` investigation** — The label scoping issue may be deeper than expected. → Mitigation: if the fix is complex, document the root cause and keep the tests disabled with a clear tracking comment, rather than shipping a fragile fix.

- **`keyword?` semantics** — Checking for `":"` prefix means any symbol starting with colon is a keyword, even if manually created. This matches ECE reader behavior and is the correct semantics for the language. No risk.
