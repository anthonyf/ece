# Diagnose and Fix Trailing `MC-COMPILE: #?` CRASH

**Date:** 2026-04-24
**Status:** Designed, ready for implementation plan
**Scope:** small — WAT + CL fallback improvement (Phase 1) + narrow fix at the mc-compile caller (Phase 2, if in-scope)
**Closes:** "Known follow-up" #2 in `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`

## Context

`make test-wasm` prints this line after bootstrap loads:

```
  CRASH: Unknown expression type -- MC-COMPILE: #?
```

The test count still reads `1011 passed, 0 failed` and the make-level gate (`grep -q "0 failed"` on the captured log) passes, so CI has been green throughout the code-objects work. But the CRASH message is misleading and hides a real error path.

The `CRASH` text is emitted from `wasm/test.js:262` after catching an exception raised by `ECE.runCodeObject(testCo)`. The exception's message comes from `mc-compile`'s catch-all `else` branch at `src/compiler.scm:799`:

```scheme
(else (error (string-append "Unknown expression type -- MC-COMPILE: "
                            (write-to-string expr))))
```

The `#?` string is produced by `$write-to-string-impl`'s generic fallback at `wasm/runtime.wat:3471` — emitted when the value isn't one of fixnum, float, string, symbol, boolean, null, char, pair, or vector. The actual value reaching `mc-compile` is some *tagged struct type* (one of: hash-table, code-object, compiled-procedure, continuation, primitive, parameter, port, error-sentinel), but the fallback strips that identity.

ECE test counters show 977 passed, 0 failed, which means the throw happens AFTER the per-test `for-each` loop completes — either in the summary-printing code or at top-level between test files. Needs investigation after we know the type.

## Goals

1. Make the `write-to-string` fallback informative — emit `#<type-name>` instead of `#?`, so any future error with an unrecognized value is self-diagnosing.
2. Use the improved error to identify the `mc-compile` caller in the ECE test bundle that's passing a bad value.
3. Fix that caller (or its upstream source) so the CRASH no longer fires.
4. End state: `make test-wasm` output no longer contains `CRASH:` line; `1011 passed, 0 failed` preserved.

## Non-goals

- Refactoring the ECE test bundle composition.
- Changing `mc-compile`'s dispatch structure — the `else` → error path is correct; something upstream is wrong.
- Adding per-type pretty-printers beyond `#<type-name>` identifier.
- Preserving `#?` for any specific test that currently depends on it (no such tests exist; verified by grep).

## Design

### Phase 1 — Improve `write-to-string` fallback

**WAT (`wasm/runtime.wat`):**

Replace the fallback at `$write-to-string-impl`'s end:

```wat
;; Fallback
(call $make-static-string (i32.const 35) (i32.const 63))  ;; "#?"
```

With a `ref.test`-based dispatch that identifies each tagged struct type. For each type, emit `#<type-name>`. Each tag string is a pre-interned module global (built via `array.new_fixed $string` in `$init-ascii-chars`). The implementer verifies during Phase 1 Task 1 which struct types actually exist in the module — my best guesses from prior session context are: `$hash-table`, `$code-object`, `$compiled-procedure`, `$continuation`, `$primitive`, `$parameter`, `$port`, `$error-sentinel`. Types that don't exist get dropped; new types surfaced during verification get added. A final catch-all emits `#<unknown>` so future type additions remain diagnosable.

Ordering: hash-table first (assumed most common), then code-object, then others. Fastest early-exit for hot paths.

**CL (`src/runtime.lisp`):**

Replace the catch-all at `ece-print-flat`'s `(t (prin1 x s))`:

```lisp
(t (format s "#<~A>" (ece-type-tag x)))
```

Where `ece-type-tag` is a new helper that:
- For known struct types (matching the WAT list above), returns the lowercase ECE-style name.
- For anything else, returns `(string-downcase (symbol-name (type-of x)))`, so `prin1`-like identification still happens.

Parity goal: a hash-table gets rendered the same on both hosts: `#<hash-table>`.

### Phase 2 — Diagnose and fix

Investigation-shaped; exact fix can't be pre-specified.

**Workflow:**

1. Re-run `make test-wasm 2>&1 | grep CRASH:` — capture the now-informative error.
2. Based on the revealed type, narrow the search:
   - **`#<hash-table>`**: look for `(eval …)` / `(apply …)` / `(mc-compile …)` in the test bundle that plausibly pass a hash-table.
   - **`#<code-object>`**: someone's passing a code-object where an expression is expected.
   - **`#<continuation>` / `#<compiled-procedure>`**: a resumed cont or closure being re-evaluated as source.
   - **`#<error-sentinel>`**: an error-propagation path is silently passing a sentinel to eval.
   - **Other types**: investigate as they surface.
3. `grep -rn 'eval\b\|apply\b\|mc-compile\|compile-and-go' src/ tests/` to enumerate callers.
4. Add targeted `(display …)` traces if needed.

**Exit criterion — narrow fix:** ≤20 lines, ≤2 files. If exceeded, abort Phase 2.

**Abort path:** ship Phase 1 alone as a pure diagnostic-quality improvement. Open a fresh follow-up spec for the underlying bug, using Phase 1's informative error as the starting point.

## Commits

One PR, up to 3 commits:

1. `wasm+cl: identify tagged struct types in write-to-string fallback` (Phase 1, always ships).
2. `<area>: fix <root-cause> to eliminate trailing MC-COMPILE CRASH` (Phase 2, only if narrow fix lands).
3. `roadmap: mark Known follow-up #2 shipped` (or "partially shipped — diagnostic improvement only; underlying bug tracked separately" if Phase 2 aborted).

## Testing

Integration-level only. No new automated test harness.

**Verification triad:**

1. `make test-wasm 2>&1 | tail -5` shows `1011 passed, 0 failed`.
2. `make test-wasm 2>&1 | grep -c CRASH:` returns `0` (success case) or `1` with `#<TYPE>` (Phase 1 only, if Phase 2 aborted — better diagnostic, bug still present).
3. `make test 2>&1 | tail -20` — no regressions in other suites.
4. 3× consecutive `make test-wasm` runs — no flakes in the new behavior.

## Risks

- **Phase 1 surfaces a different type than expected** (e.g., a struct type we didn't list). Mitigation: the `#<unknown>` catch-all emits a bare fallback so the WAT compile still succeeds; implementer adds the missing type.
- **Phase 2 diagnosis takes longer than a single sitting.** Mitigation: explicit abort path in §Phase 2; Phase 1 ships as an independently-valuable diagnostic improvement even alone.
- **The fix turns out to be in bootstrap-compile-time code** (i.e., the bad mc-compile call happens during archive loading, not test execution). Unlikely per the evidence (977 ECE tests passed before the throw), but if it happens, Phase 2 aborts and the problem moves to a fresh spec.
- **Struct-type identification misses a type.** Mitigation: the `#<unknown>` catch-all ensures no regression from the current `#?` behavior; we catch missing types incrementally.

## References

- `mc-compile` catch-all: `src/compiler.scm:799`.
- Current WAT fallback: `wasm/runtime.wat:3471` (in `$write-to-string-impl`).
- Current CL fallback: `src/runtime.lisp:701` (in `ece-print-flat`).
- CRASH emission site: `wasm/test.js:262`.
- ECE test runner: `wasm/wasm-test-runner.scm`.
- Roadmap bullet: `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md` (Known follow-up #2).
