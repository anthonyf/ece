## Context

Two independent but reinforcing weaknesses turn stray symbol corruption into opaque runtime crashes:

1. **WAT `$lookup-variable-value` returns null on miss.** When the register machine then feeds that null into the `compiled-procedure-entry` op dispatch, `ref.cast (ref $compiled-proc)` traps with "illegal cast". No variable name, no source location, no hint that the real issue was an unbound lookup in user code. The existing spec in `openspec/specs/wasm-runtime-errors/spec.md` already states lookup SHALL signal an error — but the implementation at `wasm/runtime.wat:1075` silently returns `ref.null eq`.
2. **ECE `read-symbol` accepts backslash inside bare tokens.** `src/reader.scm:68` reads any non-delimiter character, so a stray `\` (from zsh history expansion, paste tools, etc.) silently interns `foo\!` as an 8-character symbol. The error only surfaces much later at variable lookup.

Both runtimes already have infrastructure for surfacing errors: the WAT assign-from-op path at `wasm/runtime.wat:2146` bridges `$error-sentinel` values through ECE's `error` function with PC tracking; the ECE reader can call `(error ...)` with source location via `*source-file-name*` / `port-line` / `port-col`. We're using plumbing that already exists.

## Goals / Non-Goals

**Goals:**
- Unbound variable lookups produce `"Unbound variable: <name>"` errors at the lookup site, propagating through the existing error-sentinel bridge — catchable by `guard`, reportable with source location via the assign-from-op error path.
- WAT `$lookup-variable-value` and `$lookup-global-variable` agree with CL runtime on the exact error message format.
- ECE `read-symbol` rejects stray backslash in bare symbol tokens at read time with a clear error and source location.
- Happy-path lookup (variable found) stays branch-free — the error construction is a cold path.
- Regression tests cover both fixes on the WASM runtime.

**Non-Goals:**
- Not tightening `wat/runtime.wat $ecec-read-symbol` — that reads compiled `.ecec` bundles produced by ECE itself, which should never contain stray backslashes. Hardening it mostly catches "somebody hand-edited an .ecec file" which isn't a real workflow.
- Not implementing R7RS `|...|` pipe-quoted symbols. Out of scope.
- Not adding general reader hardening (e.g., rejecting `#`, `|` mid-symbol). If those bite us later we can add them, but this change targets exactly the observed failure mode.
- Not changing how `define-variable!` or `set-variable-value!` handle misses — those already have sensible behavior (`set!` on unbound already errors; `define!` always succeeds).

## Decisions

### Decision 1: Error sentinel, not direct `$js-runtime-error` call

When `$lookup-variable-value` misses, it returns a fresh `$error-sentinel` struct containing the `"Unbound variable: <name>"` message and empty irritants, instead of calling `$signal-error-str` (which throws a JS exception unconditionally).

**Rationale:** `$error-sentinel` values are already bridged by the assign-from-op dispatch (`wasm/runtime.wat:2146`) and the test dispatch (`wasm/runtime.wat:2211`). Routing through that bridge gets us four things for free:
1. ECE's `error` function is invoked with the correct `error-object`, so `guard` catches it.
2. The bridge records `$error-space-id` and `$error-pc`, so source-map resolution can report file/line.
3. When `$error-sym` isn't yet bound (during early boot), the bridge falls back to `$signal-error-str` — same behavior we want for a bootstrap unbound lookup.
4. Primitives that call `$lookup-variable-value` internally (e.g., `%lookup-variable-value`) can keep behaving identically because the sentinel flows out as their return value.

**Alternative considered:** Call `$signal-error-str` directly for a fatal error. Rejected because it makes the error uncatchable by `guard`, which breaks a key ECE invariant (user errors should be programmatically recoverable). The spec in `error-signaling` requires this.

**Alternative considered:** Return null and have every caller check. Rejected — that's the status quo; we have too many callers to audit.

### Decision 2: Lookup return type changes from `(ref null eq)` to `(ref eq)` only if feasible

If we can make `$lookup-variable-value` always return a non-null value (either the binding or an error sentinel), we tighten the type signature. This catches any future regression at assembly time.

**Rationale:** `(ref null eq)` is load-bearing today because callers expect null on miss. Once we replace the null path with an error sentinel, no caller should see null again. Tightening to `(ref eq)` turns "forgot to handle the error sentinel" into a WAT compile error rather than a latent `ref.cast` trap.

**Trade-off:** May require auditing all call sites for places that pass null as an "absent variable" signal. If that's pervasive, back off and keep `(ref null eq)`. Left as a follow-up if it balloons scope.

### Decision 3: `$lookup-global-variable` mirrors `$lookup-variable-value`

Op ID 1 (`lookup-global-variable`) at `wasm/runtime.wat:2451` has the same behavior: returns the lookup result, which could be null. Apply the same sentinel treatment so both op paths behave identically.

### Decision 4: Reader rejects backslash only inside bare symbols

`read-symbol` in `src/reader.scm` adds a check: if the current character is `#\\`, call `error` with a message like `"invalid character in symbol: \\ (at file:line:col)"` and the partial buffer as context. String literals and character literals (`#\\`) already consume `\` via their own paths and are unaffected.

**Rationale:** The exclusion list is minimal — only `\`. Other characters that could theoretically cause trouble (`|`, `#`, `'`) are left permissive so we don't break existing legitimate ECE source. The bootstrap loads cleanly today, so adding this check can't regress anything that already works.

**Source location:** use `port-line` and `port-col` via the same mechanism `ece-scheme-read` uses for list-location tracking (`src/reader.scm:322-327`).

### Decision 5: CL runtime alignment

The CL `lookup-variable-value` (`src/runtime.lisp`) already signals unbound via `ece-runtime-error` with message starting `"Unbound variable: "`. Verify the exact format and, if needed, adjust one side so both runtimes emit byte-identical error messages. Small fix — likely zero lines of code if they already match.

## Risks / Trade-offs

- **[Risk] Error sentinel allocation on hot path.** → Mitigation: sentinel is only constructed on the miss branch (after the `$not-found` block exits). The happy-path scan loop is untouched. Profile before/after to confirm no regression on a lookup-heavy benchmark.
- **[Risk] Some caller of `$lookup-variable-value` treats null as "absent" and depends on that.** → Mitigation: grep all callers before changing the return type. If any legitimately want the absent-as-null behavior, give them a helper `$try-lookup-variable-value` that keeps the old signature, and use the sentinel-emitting version only from the op dispatch paths.
- **[Risk] Reader rejection triggers on legitimate ECE source during bootstrap.** → Mitigation: `grep -r '\\' src/*.scm` before committing; current tree has no bare-symbol backslashes. Bootstrap test catches any regression immediately.
- **[Risk] Error message format drift between WAT and CL runtimes causes flaky cross-platform tests.** → Mitigation: a single conformance test that evaluates `(guard (e ((error-object? e) (error-object-message e))) undefined-var)` on both runtimes and asserts identical strings.
- **[Trade-off] Not implementing R7RS `|...|` pipe-quoted symbols means stray `|` still passes through.** → Acceptable — no one has hit that, and adding pipe-quoting is a meatier change.

## Migration Plan

1. Modify WAT `$lookup-variable-value` to emit error sentinel on miss.
2. Verify `$lookup-global-variable` behavior matches.
3. Rebuild `wasm/runtime.wasm` via `make wasm`.
4. Run `make test-wasm` — verify no regressions, then add new tests for the unbound-variable scenario.
5. Align CL-side message format if it drifts from the WAT format.
6. Modify `src/reader.scm` `read-symbol` to reject `\`.
7. Run `make bootstrap` — the two-pass bootstrap must succeed. If it fails, investigate and fix the offending source file (there shouldn't be any).
8. Add an ECE test for reader rejection.
9. Run the full test suite (`make test`) before PR.

No feature flags, no gradual rollout — this is a bug-fix-class change that should behave identically for all programs that work today and better for all programs that were silently broken.
