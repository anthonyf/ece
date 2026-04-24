# Re-enable WASM Yield Tests

**Date:** 2026-04-24
**Status:** Designed, ready for implementation plan
**Scope:** small — WAT surgical fix + three test bodies restored + TODO cleanup
**Closes:** "Known follow-up" #1 in `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`

## Context

Three WASM yield tests were removed from `wasm/test.js` in commit `7403276` (the P0 `$comp-space` retirement): `yield single frame`, `yield multi-frame (3 cycles)`, `handle table stable over 100 yield cycles`. They traced an `illegal cast` trap through `do-continuation-winds` (op 19 in `wasm/runtime.wat`) under the then-new 2-param `$execute` signature. The TODO at `wasm/runtime.wat:2711` hypothesizes the root cause: the continuation's `$conts` field may still hold a legacy `(space-id . pc)` pair instead of a `$code-object`, OR `do-winds!` is being invoked with a null `$code-obj`.

ECE-level `call/cc` + `dynamic-wind` tests (`test-callcc.scm`, `test-dynamic-wind.scm`) pass on WASM today (part of the 1008/0 baseline), which means the bug is narrow — specific to the `%yield!` path or to how continuations captured via yield get resumed from the JS host. Not a structural issue with continuations generally.

## Goals

1. Restore the three yield tests in `wasm/test.js` — full original bodies, not simplified stand-ins.
2. Diagnose the underlying `illegal cast` from a real trap location (not from a priori hypothesis).
3. Apply a narrow WAT fix at the site identified by the diagnosis.
4. `make test-wasm` shows `1011 passed, 0 failed` (previous 1008 baseline + 3 re-enabled).

## Non-goals

- **Moving tests to ECE-level `.scm`.** These validate the JS↔WASM yield-resume boundary: ECE calls `(yield)` → executor returns to JS → JS calls `get_yield_cont()` + `call_continuation()` to resume. After `(yield)` the executor isn't running, so an ECE-only version can't orchestrate the resume. ECE-level `call/cc` + `dynamic-wind` coverage already exists.
- **Restructuring continuation representation.** The diagnosis will dictate a surgical edit; if Phase 1 reveals a structural fix, this spec aborts with a follow-up note and the tests stay disabled.
- **New WASM test infrastructure.** The three existing tests are the deliverable; no extensions or refactors.
- **Addressing the `CRASH: MC-COMPILE: #?` diagnostic** (Known follow-up #2). That's separately tracked. If the yield-tests fix happens to eliminate it, note in the commit message; otherwise leave it.

## Design

### 1. Two-phase execution in a single PR

**Phase 1 — Reproduce and diagnose (uncommitted exploration):**

1. Recover the three test bodies from git: `git show 7403276^ -- wasm/test.js | sed -n '60,150p'` contains the full bodies. They go into `wasm/test.js` at the current TODO block site, between the op-id loop and the `runtime_error produces readable exception` test.

2. Run `make test-wasm 2>&1 | tee /tmp/claude/yield-repro.log`. Expect three failures.

3. For each failure, extract from the JS-side stack trace:
   - WAT function index (e.g., `wasm-function[203]`).
   - Byte offset within that function (e.g., `0x67fe`).
   - Exception kind (expected `illegal cast`; verify it's not drifted to something else since the TODO was written).

4. Map function indices to names via `wasm-objdump -j Function -x wasm/runtime.wasm | grep -E '^\s*[0-9]+:'` (Binaryen's tool), or by grepping the WAT for low-numbered helpers. Function 33/34 were previously `$xcar`/`$xcdr`; similar mapping expected here.

5. With the trap location in hand, read the WAT path backwards. Look for whichever `ref.cast (ref $code-object)` or `ref.cast (ref $pair)` is traversing a value of the wrong shape. Most likely culprits (in decreasing order of plausibility):

   - **Hypothesis A:** `$continuation.$conts` holds a `$pair` of `(legacy-space-id . pc)` instead of a pair where the car is a `$code-object`. Some later `ref.cast` on `(car conts)` traps.
   - **Hypothesis B:** `do-winds!` is invoked with a null `$code-obj` because the thunk it dispatches has a null code-object field. A later `ref.as_non_null` or `ref.cast` traps.
   - **Hypothesis C:** `%yield!` itself mis-shapes the stashed continuation — residue from the migration.

### 2. Phase 1 exit criteria

- **Narrow fix identified** (single ref.cast site, or one missing `struct.set $code-object`, or one residual `(cons space-id pc)` construction): proceed to Phase 2 in this session.
- **Structural fix required** (continuation representation needs overhaul, multiple coordinated call-site changes): abort this spec. Update the TODO at `wasm/runtime.wat:2711` with the concrete root cause found. Open a fresh brainstorm for the structural work.

**Timebox:** ~90 minutes for Phase 1. If the diagnosis isn't converging, exit via the abort path.

### 3. Phase 2 fix + verification

**Fix shape (expected, not specified in advance):** 1-10 lines of WAT at the site Phase 1 identifies. Likely categories:

- A missing `struct.set $code-object` on a continuation field during capture or resume.
- A residual `(cons space-id pc)` construction that should be a direct `$code-object` ref.
- A `ref.cast (ref $code-object)` that should be a `ref.cast (ref eq)` + type-test branch.

**Verification (in order):**

1. `make test-wasm 2>&1 | tail -5` shows `1011 passed, 0 failed`. No `FAIL:` or `CRASH:` lines for the three restored test names.
2. `make test 2>&1 | grep -E 'passed|failed' | tail -10`. No regressions in the broader suite.
3. Run `make test-wasm` three times consecutively; all three pass. Guards against flaky handle-table interactions (especially relevant for "handle table stable over 100 yield cycles").

### 4. Commits (single PR)

1. **`wasm: fix <root-cause-summary> to restore yield tests`** — WAT surgical edit + three test bodies restored + removal of the TODO block in `wasm/test.js` + removal of the TODO at `wasm/runtime.wat:2711`.
2. **`roadmap: mark WASM yield tests re-enabled`** — update `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`'s Known follow-ups section, flipping bullet #1 from "disabled" to "Shipped" with a pointer to this PR.

## Test plan

Enumerated in §3 "Verification". No new automated test infrastructure; the three restored tests are the coverage.

## Risks

- **Diagnosis takes longer than the timebox.** Mitigation: hard 90-minute budget. Exit cleanly with an updated TODO; tests stay disabled; nothing regresses.
- **The root cause turns out to be structural.** Mitigation: Phase 1 exit criteria explicitly allow bailing; spec honors the non-goal of "no continuation-representation restructuring."
- **Fix introduces new regressions in the broader suite.** Mitigation: §3 step 2 runs the full `make test`; any regression blocks the merge.
- **Flaky test — 99 passes then one fail on the 100-cycle handle-stability test.** Mitigation: §3 step 3 runs three times consecutively. If one of the three fails, that signals an incomplete fix, not a flake — investigate before merging.

## References

- Removed tests' bodies: `git show 7403276^ -- wasm/test.js` (lines ~60-150 of the output).
- Current TODO in test.js: `wasm/test.js:55`.
- Current TODO in WAT: `wasm/runtime.wat:2711` (op 19 `do-continuation-winds`).
- Yield definition: `src/prelude.scm:454`.
- `%yield!` primitive dispatch: `grep '%yield!\|$yield' wasm/runtime.wat` (for Phase 1 reading).
- Related ECE-level tests that currently pass: `tests/ece/common/test-callcc.scm`, `test-callcc-tco.scm`, `test-dynamic-wind.scm`.
- Roadmap: `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`, Known follow-ups section.
