## Context

ECE has two runtimes executing the same compiled bytecode:
- **CL runtime** (`src/runtime.lisp`, ~1970 lines) — tagged lists for continuations, compiled-procedures, primitives
- **WASM runtime** (`wasm/runtime.wat`, ~5900 lines) — GC structs for continuations, compiled-procedures, primitives

Testing infrastructure has diverged:
- CL tests: `run-all.scm` → `run-common.scm` + `run-cl.scm`, driven by `(load ...)` calls
- WASM tests: `WASM_TEST_SRCS` in Makefile, concatenated into one file, compiled, run in Node.js
- 4 test files excluded from WASM (`test-callcc-tco.scm`, `test-errors.scm`, `test-error-messages.scm`, `test-file-io.scm`)
- Conformance tests pass 157/157 but CI ignores failures (`continue-on-error: true`)

The tail-position call/cc compiler path (added in PR #82) generates valid instructions that both runtimes should handle, but the WASM runtime hangs on it. The test was moved to a CL-only file as a workaround.

## Goals / Non-Goals

**Goals:**
- Both runtimes run the same test suite (one manifest, platform guards for differences)
- CI catches any regression: test failures, test count drops, conformance failures
- WASM runtime handles tail-position call/cc correctly
- Tests use abstract predicates, not representation-specific checks

**Non-Goals:**
- `operations.def` manifest (deferred to separate change)
- Compiler golden-file tests (deferred to bytecode-flattening change)
- New test coverage beyond what's needed to close platform gaps
- Changing the WASM representation to match CL (structs are the right choice for WASM)

## Decisions

### 1. Unified test manifest via run-common.scm

**Decision**: `run-common.scm` becomes the single source of truth. The Makefile's `WASM_TEST_SRCS` is generated from it (or replaced by a script that parses it).

**Alternative considered**: A separate `test-manifest.txt` listing files. Rejected because `run-common.scm` already serves this purpose and load-order matters (framework must come first).

**How it works**: All test files go in `run-common.scm`. Platform-specific tests use `(when (platform-has? 'feature) ...)` guards inside the test files themselves. The WASM build step concatenates the same files that `run-common.scm` loads.

### 2. Guard-based assert-error (replacing try-eval dependency)

**Decision**: Rewrite `assert-error` as a macro using `guard` instead of `try-eval`. This works on both platforms.

```scheme
(define-macro (assert-error expr)
  `(guard (e (#t (set! *test-passes* (+ *test-passes* 1))))
     ,expr
     (begin
       (set! *test-failures* (+ *test-failures* 1))
       (display "    FAIL: expected error from ")
       (display ',expr)
       (newline))))
```

**Alternative considered**: Keep `assert-error` using `try-eval` and wrap calls in `(when (platform-has? 'try-eval) ...)`. Rejected because this leaves large swaths of error-handling tests unverified on WASM.

### 3. WASM tail-position call/cc fix

**Decision**: Debug and fix the WASM instruction dispatch for the tail-position call/cc pattern. The compiler emits these instructions for tail-position `(%raw-call/cc receiver)`:

```
(assign argl (op capture-continuation) (reg stack) (reg continue))
(assign argl (op list) (reg argl))
(test (op primitive-procedure?) (reg proc))
(branch (label callcc-primitive))
(test (op continuation?) (reg proc))
(branch (label callcc-continuation))
;; compiled procedure: tail call
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
callcc-primitive
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
(goto (reg continue))
callcc-continuation
(assign val (op car) (reg argl))
(perform (op do-continuation-winds) (reg proc))
(assign stack (op continuation-stack) (reg proc))
(assign continue (op continuation-conts) (reg proc))
(goto (reg continue))
```

The key difference from non-tail: no `return-label`, uses caller's `continue` register directly. All operations exist in WASM. The likely issue is either:
- Stack not being restored properly between iterations (accumulating frames)
- The `(goto (reg continue))` path not handling space-qualified addresses correctly when continue was set by `capture-continuation`

Investigation approach: reduce iteration count to 3, add WASM trace output, identify where frames accumulate.

### 4. Abstract continuation predicates in tests

**Decision**: Replace all `(pair? k)` / `(car k) = 'continuation` patterns with `(continuation? k)`. This predicate (primitive 156) works on both platforms — it checks the tagged-list tag on CL and the struct type on WASM.

For test-serialization.scm (CL-only): also fix the assertions there for consistency, even though that file only runs on CL. Prevents copy-paste bugs.

### 5. Test-count regression check

**Decision**: Store passing test counts in a checked-in file (e.g., `tests/test-counts.json`). CI compares actual counts against baselines and fails if any count drops.

```json
{
  "cl-ece": 497,
  "cl-rove": 42,
  "wasm-ece": 493,
  "wasm-integration": 34,
  "conformance": 157
}
```

Counts are updated manually (or by a make target) when new tests are added. This catches silent test removal, broken test registration, and platform drift.

### 6. Conformance tests blocking

**Decision**: Remove `continue-on-error: true` from `.github/workflows/test.yml`. The conformance suite already has a `conformance-skip!` mechanism for known-failing tests — if a test can't be fixed immediately, it can be marked as skipped with a reason.

## Risks / Trade-offs

**[Risk] WASM tail-call/cc fix may be complex** → Mitigation: Start with minimal reproduction (3 iterations), use WASM trace infrastructure. If the fix requires significant WASM runtime changes, it can be split into a sub-PR.

**[Risk] Guard-based assert-error may behave differently than try-eval** → Mitigation: `guard` is already the standard error-handling mechanism in ECE. The only difference is that `try-eval` returns eof on error while guard catches. Test behavior should be equivalent.

**[Risk] Unifying test manifests may cause WASM compile-time to increase** → Mitigation: The 4 newly-included files are small (~300 lines total). Compilation overhead is negligible.

**[Trade-off] Test-count baselines require manual updates** → Acceptable: this is intentional friction — you should notice when test counts change. A make target can help: `make update-test-counts`.
