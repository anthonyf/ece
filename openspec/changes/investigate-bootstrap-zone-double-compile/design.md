## Context

CI runs two **separate** SBCL processes that each need to load `:ece`, and the `make ece` target uses the second one. Abridged `.github/workflows/test.yml` flow (original order, before this change):

```
1. actions/cache@v4              → restore .fasl-cache/ (may be stale, prefix-match)
2. Warm FASL cache               → SBCL #1 at --dynamic-space-size 8192,
                                   runs `(asdf:load-system :ece)`, triggers
                                   load-compiled-zones, writes fresh zone FASLs
3. Install binaryen              → curl + tar
4. Setup Node.js                 → actions/setup-node@v4
5. Mark bootstrap outputs as up-to-date
                                 → `sleep 1 && touch bootstrap/*-zone.lisp`
                                   (load-bearing for `make`'s dependency tracking)
6. Build ece binary              → `make ece` → SBCL #2 at --dynamic-space-size 4096,
                                   runs `(asdf:load-system :ece)` AND
                                   `(ece:evaluate (compile-system ...))`
```

The relevant `Makefile:28-33` target that SBCL #2 executes:

```
qlot exec sbcl --dynamic-space-size 4096 --non-interactive --disable-debugger \
  --eval '(asdf:load-system :ece)' \
  --eval '(ece:evaluate (list (intern "compile-system" :ece) (quote (quote ("src/sdk-lib.scm" "src/ece-unit.scm" "src/ece-main.scm" "src/ece-build.scm" "src/ece-test.scm"))) "share/ece/ece-main.ecec"))' \
  --quit
```

The failure initially *looked* like a single SBCL process recompiling `reader-zone.lisp` twice:

```
01:49:03 ; compiling file "bootstrap/reader-zone.lisp"   ← first compile, SBCL #1
01:49:23 ; wrote .fasl-cache/bootstrap/reader-zone.fasl
...
01:52:00 ; compiling file "bootstrap/reader-zone.lisp"   ← second compile, SBCL #2
01:52:13 Heap exhausted, game over.
```

Once the step boundaries around those two events are inspected (line-by-line in `gh run view --log`), it becomes clear they straddle the gap between `Warm FASL cache` (SBCL #1, 8GB) and `Build ece binary` (SBCL #2, 4GB). They are **two separate OS processes**, not one image with two compiles — a GC boundary between them, but the second process starts with a fresh heap.

### Why SBCL #2 recompiles

SBCL #2 recompiles because `load-compiled-zones` (in `src/runtime.lisp`) checks `(> (file-write-date source) (file-write-date fasl))` before loading each zone. After the original step ordering:

1. Warm FASL cache (T2): writes fresh FASLs at mtime T2 > restored-cache mtimes.
2. Mark bootstrap outputs as up-to-date (T3 > T2): touches `bootstrap/*-zone.lisp`, setting source mtimes to T3.
3. Build ece binary (T4): `load-compiled-zones` sees source T3 > FASL T2 → recompiles all 7 zones **from scratch at 4GB**, which is right at the memory margin and OOMs non-deterministically.

The touch step is load-bearing for `make`'s dependency tracking (prevents `$(ZONE_SENTINEL)` from re-running because `src/*.scm` and `primitives.def` have equal-ish checkout mtimes to bootstrap outputs), so it can't just be removed.

### Why SBCL #1's (original-ordering) FASLs still matter

The mtime check in `load-compiled-zones` is load-bearing as a stale-cache safety net: if `actions/cache@v4`'s `restore-keys: fasl-` prefix match restores FASLs from an older commit with different zone content, the mtime check detects that (source newer than restored FASL) and recompiles them. An earlier iteration of this change (PR #147 commit `516e647`) removed the mtime check entirely; that caused warm-cache to load stale restored FASLs as-is, and `compile-system` later failed at runtime with `Unknown label: NIL` inside `strip-source-locations`. The commit was reverted.

## Goals / Non-Goals

**Goals:**
- Eliminate the redundant zone recompilation in the `Build ece binary` CI step, so SBCL #2 loads the FASLs that SBCL #1 already compiled instead of redoing the work.
- Preserve the existing `load-compiled-zones` mtime check as a stale-cache safety net (it is the only guard against `actions/cache@v4`'s prefix-match restore pulling in FASLs from an incompatible commit).
- Confirm that after the fix, `Build ece binary` at 4GB runs `(ece:evaluate (compile-system ...))` without hitting `Heap exhausted`, and the CI log shows no `; compiling file "bootstrap/*-zone.lisp"` lines in that step.

**Non-Goals:**
- Change the SBCL heap ceiling. A ceiling bump was considered and rejected as masking (PR #146, closed). The existing Makefile targets stay at `--dynamic-space-size 4096`; only the CI `Warm FASL cache` step uses 8192, and that is a headroom allowance specific to pre-warming, not the normal build budget.
- Rearchitect `compile-system`, `load-compiled-zones`, or the bootstrap flow. The fix is a single CI step reorder.
- Rework the CI caching strategy. `actions/cache@v4` with `restore-keys: fasl-` stays in place. The fix relies on the `load-compiled-zones` mtime check to revalidate stale restores in SBCL #1 (warm-cache) and to skip-load cleanly in SBCL #2 (build-ece).
- Improve compile *speed* of `reader-zone.lisp` itself. That is a separate conversation about `src/prelude.scm` splitting.

## Decisions

### 1. Reorder `.github/workflows/test.yml` instead of changing source

**Choice:** Move the `Mark bootstrap outputs as up-to-date` step so it runs **before** `Warm FASL cache` instead of after. No changes to `src/runtime.lisp` or `Makefile`.

**Rationale:** The mtime check in `load-compiled-zones` is the right mechanism in general — it's what guards against stale cache restores. The bug is the ORDER in which CI steps produced their mtimes, not the check itself. With `touch` running first:

1. Source mtimes become T1.
2. `Warm FASL cache` (SBCL #1, 8GB) reads the mtime check, sees T1 > restored-cache mtime → recompiles zones → writes fresh FASLs at T2 > T1. (At 8GB, recompile is safe.)
3. `Build ece binary` (SBCL #2, 4GB) reads the mtime check, sees T1 < T2 → skips recompile → loads FASLs. Peak heap stays small.

This preserves correctness (mtime check still revalidates stale restores in SBCL #1) and eliminates redundancy (SBCL #2 no longer recompiles).

**Alternatives considered:**
- **Remove the mtime check in `load-compiled-zones`.** Tried in PR #147 commit `516e647`. Failed in CI: stale FASLs from a prefix-match cache restore loaded without revalidation, and `compile-system` crashed with `Unknown label: NIL` inside `strip-source-locations`. Reverted.
- **Bump the `make ece` SBCL heap from 4GB to 8GB.** Considered in PR #146. Rejected as masking: doesn't address the redundant work, shifts the ceiling, and the next bootstrap expansion would require bumping again.
- **Remove the CI touch step.** Rejected because it's load-bearing for `make`'s dependency tracking.
- **Split the Makefile target into two SBCL processes.** Rejected because the existing CI already has two processes (warm-cache and build-ece) via the warm-cache step; the fix uses that structure instead of adding a third.

### 2. Keep the mtime check in `load-compiled-zones` as the stale-cache guard

**Choice:** Do not touch `src/runtime.lisp`. The existing `(> (file-write-date source) (file-write-date fasl))` check stays.

**Rationale:** Without the check, any prefix-matched cache restore would load stale FASLs verbatim. That's the failure mode the first PR #147 attempt hit. The check is cheap (two `stat` calls per zone file) and it's the only mechanism that distinguishes "FASLs from the same commit" from "FASLs from a different commit that happened to share a cache-key prefix."

### 3. Verify by reading the post-fix CI log, not by local reproduction

**Choice:** Validate with the actual CI run on this PR rather than trying to reproduce the `actions/cache` prefix-match behavior locally.

**Rationale:** The failure depends on GitHub Actions cache restore semantics, which aren't replicable without running GitHub Actions. Local reproduction was valuable during the investigation (it confirmed the two-process structure and the mtime-race mechanics) but the final fix validation has to be in CI. Criterion: no `; compiling file "bootstrap/*-zone.lisp"` lines in the `Build ece binary` step's output.

## Risks / Trade-offs

- **[Cannot reproduce locally]** If the double compile only manifests in the GitHub Actions environment (e.g., because of the `touch bootstrap/*-zone.lisp` step or the cache restore), local investigation will be harder. → **Mitigation**: replicate the CI's exact pre-`make ece` setup (touch the files, optionally prime the FASL cache) in a local script. If that still doesn't reproduce, add targeted logging to the ASDF load path and run it in CI as a diagnostic branch.

- **[Fix lands but ceiling goes up anyway later]** Even after eliminating the duplicate compile, `reader-zone.lisp` on its own is >1GB of compile heap. The next time someone adds a few thousand lines to `src/prelude.scm`, we might hit the ceiling again from a single compile. → **Mitigation**: out of scope for this proposal, but note it in the task that the real long-term fix is splitting `prelude.scm` into multiple zones.

- **[Investigation takes longer than expected]** Dark corners of ASDF interaction can consume hours. → **Mitigation**: time-box. If the investigation exceeds 4 hours of focused work without a clear cause, fall back to Decision 1's alternative (split the Makefile target into two SBCL invocations) and document it as a temporary measure.

- **[Fix interacts with CI caching]** A fix that changes how FASLs are written could invalidate the existing `actions/cache@v4` keyed on `hashFiles(...)`, forcing a full cache rebuild on first run. → **Mitigation**: acceptable one-time cost. Cache rebuilds naturally over subsequent runs.

## Migration Plan

Not applicable — this is an internal build-flow correctness fix, not a user-facing change. No deployed state, no API, no data migration.

## Open Questions

- Is the CI `Mark bootstrap outputs as up-to-date` step actually still needed after the reorder? It was added to prevent `make`'s dependency tracking from re-running `$(ZONE_SENTINEL)`. With the reorder, it still fills that role, but nobody has actually proven the failure mode it guards against ever fires with a post-`actions/checkout@v4` working tree. Worth a follow-up to test removing it entirely and seeing if `make ece` still behaves.
- Is there a CI-level fix for the `restore-keys: fasl-` prefix match that can make the `Warm FASL cache` step skip when the restored cache is stale, rather than relying on `load-compiled-zones`'s mtime check to catch it? `actions/cache@v4` supports more granular key strategies; this could be folded in as a future improvement.
- The `load-compiled-zones` mtime check is now a soft contract between `src/runtime.lisp` and `.github/workflows/test.yml`: one expects the other to put source mtimes strictly older than FASL mtimes during `Build ece binary`. The two files don't cross-reference. Worth a comment in `test.yml` pointing at `load-compiled-zones` — already added inline in this PR.
