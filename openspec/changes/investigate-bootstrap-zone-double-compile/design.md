## Context

The `share/ece/ece-main.ecec` Makefile target (Makefile:28-33) runs a single SBCL process with two conceptually distinct steps:

```
qlot exec sbcl --dynamic-space-size 8192 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --eval '(ece:evaluate (list (intern "compile-system" :ece) (quote (quote ("src/sdk-lib.scm" "src/ece-unit.scm" "src/ece-main.scm" "src/ece-build.scm" "src/ece-test.scm"))) "share/ece/ece-main.ecec"))' \
  --quit
```

Step 1: `(asdf:load-system :ece)` — ASDF loads the ECE CL system, which includes `bootstrap/*-zone.lisp` files. If their FASLs are out of date or missing, ASDF compiles them from source and writes them to `.fasl-cache/` via `ASDF_OUTPUT_TRANSLATIONS`. This is where the first compilation of `bootstrap/reader-zone.lisp` happens — a ~376k-line file that takes ~20s to compile and allocates roughly a gigabyte of SBCL heap.

Step 2: `(ece:evaluate (compile-system ...))` — this is ECE's own build step, running inside the just-loaded system, compiling five `.scm` SDK source files into a single `share/ece/ece-main.ecec` bundle.

The observed failure (CI log excerpt):

```
01:49:03 ; compiling file "bootstrap/reader-zone.lisp"
01:49:23 ; wrote .fasl-cache/bootstrap/reader-zone.fasl      ← first compile, 20s
...
01:52:00 ; compiling file "bootstrap/reader-zone.lisp"       ← second compile, 3 min later
01:52:13 Heap exhausted, game over.
```

The second compile at 01:52:00 is the puzzle. By that point step 1 has already completed (reader-zone is loaded), and we are inside step 2 (`ece:evaluate`). Yet SBCL/ASDF is recompiling the same `.lisp` file from scratch. At that point step 1's residual heap has not been released (no GC pressure has forced it), so the peak doubles and SBCL OOMs on constraint-propagation in IR1.

### Hypotheses for the duplicate compile

1. **ASDF freshness re-check**: something during `compile-system` forces a reload of `:ece`, and ASDF compares mtimes between the source `.lisp` and the `.fasl-cache/...fasl`, concludes the source is newer (because `touch bootstrap/*-zone.lisp` happens in CI, or because of clock skew, or because the FASL output translation path differs per-session), and recompiles. Inspection of CI's "Mark bootstrap outputs as up-to-date" step (`test.yml:59-64`) confirms a `touch bootstrap/*-zone.lisp` runs before `make ece`, which suggests this is at least partially about mtime freshness.
2. **ECE evaluate side-effect**: `ece:evaluate` or `compile-system` internally calls `(asdf:load-system :ece :force ...)` or similar, or manually invokes `compile-file` on the zone file, bypassing the FASL cache.
3. **Output-translation mismatch**: the first load writes to one cache directory (derived from `CURDIR/`), the second load uses a different output-translation base (maybe unset inside the ECE environment), ASDF sees no cached FASL where it looks, recompiles.
4. **`*features*` or environment change between the two steps**: some pushnew happens in step 1 that makes the system "dirty" for step 2, triggering a recompile of dependents.

The actual cause needs to be isolated by instrumenting or tracing.

## Goals / Non-Goals

**Goals:**
- Identify *which* code path triggers the second compile.
- Eliminate the duplication so that a fresh `make ece` invocation compiles `bootstrap/*-zone.lisp` files at most once per SBCL image.
- Confirm that after the fix, peak SBCL heap during `make ece` drops back under the existing 4GB ceiling and CI goes green without any heap bump.

**Non-Goals:**
- Change the SBCL heap ceiling. A ceiling bump was considered and rejected as masking. The existing 4GB stays in place and the fix has to land within that budget.
- Rearchitect `compile-system` or the bootstrap flow. Scope is limited to finding the duplicate invocation and removing it.
- Rework CI caching strategy. The `actions/cache@v4` block in `test.yml` is orthogonal — a fresh cache miss should still compile each zone only once.
- Improve compile *speed* of `reader-zone.lisp` itself (eliminate inlining passes, reduce IR1 work, etc.). That is a separate conversation about `src/prelude.scm` and the generated zone splitting.

## Decisions

### 1. Investigation-first, fix-second

**Choice:** This change is staged as "investigate, then fix" — the tasks list starts with diagnostic steps (reproduce, instrument, identify cause) before any code change. The nature of the fix depends on which of the hypotheses above is correct.

**Rationale:** Guessing at a fix without identifying the cause is likely to either (a) not actually eliminate the double compile, or (b) introduce regressions in the ASDF/ECE interaction. The investigation itself is the expensive part; once we know which code path is triggering the second compile, the fix is almost certainly 1-5 lines.

**Alternatives considered:**
- "Just split the invocation into two SBCL processes" — this *might* work (the first image exits releasing its heap, the second starts fresh and reloads from FASL cache, no duplicate compile in one image). Rejected as the primary plan because it addresses the symptom (peak heap in one image) rather than the cause (why is it recompiling at all), and because it doubles SBCL startup cost for every `make ece`. Keeping it as a fallback if the cause turns out to be intractable.

### 2. The fix lives close to the cause

**Choice:** Once the cause is identified, the fix will be made in the smallest scope possible — e.g., if `compile-system` is calling `asdf:load-system :force t`, just remove that. If ASDF is recompiling because of output-translation mismatch, fix the translation. If ECE is manually compile-filing the zone, stop doing that.

**Rationale:** The bootstrap flow is load-bearing and under-tested; any broad refactor risks breaking more than it fixes. A surgical cut where the duplicate work originates is the lowest-risk change.

### 3. Verify with a deterministic reproduction, not just CI

**Choice:** The task list requires reproducing the double-compile *locally* with a scripted invocation, not just observing it in CI.

**Rationale:** CI reproduction is slow and the feedback loop is painful. A local reproduction makes iteration on hypotheses tractable and gives us a scripted regression test we can re-run after the fix.

## Risks / Trade-offs

- **[Cannot reproduce locally]** If the double compile only manifests in the GitHub Actions environment (e.g., because of the `touch bootstrap/*-zone.lisp` step or the cache restore), local investigation will be harder. → **Mitigation**: replicate the CI's exact pre-`make ece` setup (touch the files, optionally prime the FASL cache) in a local script. If that still doesn't reproduce, add targeted logging to the ASDF load path and run it in CI as a diagnostic branch.

- **[Fix lands but ceiling goes up anyway later]** Even after eliminating the duplicate compile, `reader-zone.lisp` on its own is >1GB of compile heap. The next time someone adds a few thousand lines to `src/prelude.scm`, we might hit the ceiling again from a single compile. → **Mitigation**: out of scope for this proposal, but note it in the task that the real long-term fix is splitting `prelude.scm` into multiple zones.

- **[Investigation takes longer than expected]** Dark corners of ASDF interaction can consume hours. → **Mitigation**: time-box. If the investigation exceeds 4 hours of focused work without a clear cause, fall back to Decision 1's alternative (split the Makefile target into two SBCL invocations) and document it as a temporary measure.

- **[Fix interacts with CI caching]** A fix that changes how FASLs are written could invalidate the existing `actions/cache@v4` keyed on `hashFiles(...)`, forcing a full cache rebuild on first run. → **Mitigation**: acceptable one-time cost. Cache rebuilds naturally over subsequent runs.

## Migration Plan

Not applicable — this is an internal build-flow correctness fix, not a user-facing change. No deployed state, no API, no data migration.

## Open Questions

- Is the `touch bootstrap/*-zone.lisp` step in `test.yml` (lines 59-64) load-bearing? It was added to "mark bootstrap outputs as up-to-date" — but that exact `touch` might be what triggers ASDF's freshness re-check and causes the second compile. Worth inspecting what that step guards against and whether it's still needed.
- Does the double-compile happen on *all* `*-zone.lisp` files or only on `reader-zone.lisp`? The log only shows the reader-zone crash because reader-zone is the biggest and OOMs first. Instrumenting the whole load path will show whether it's a reader-zone-specific quirk or a systemic pattern.
- Is there a lighter-weight way to verify the fix than re-running the full `make ece` each iteration? e.g. a minimal reproduction that loads the system twice in a single SBCL REPL and counts `compile-file` invocations on zone files. Almost certainly yes — worth building as the first diagnostic.
