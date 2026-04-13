## Why

Main has been red since PR #144 with SBCL `Heap exhausted during garbage collection` while compiling `bootstrap/reader-zone.lisp` during `make ece`. A ceiling bump from 4GB to 8GB was considered and rejected as a masking fix: it does not address the real problem, and it shifts the ceiling without buying time against future bootstrap expansion. (Failed PR #146 closed.) An earlier attempt to remove the mtime check in `load-compiled-zones` also failed because `actions/cache`'s `restore-keys: fasl-` prefix-match loaded stale FASLs without revalidation. (Failed PR #147 commit `516e647`, reverted.)

**Root cause (confirmed 2026-04-13 via CI log step-boundary analysis and local reproduction):** Two separate SBCL processes in CI each independently compile all 7 bootstrap zones from source, wasting ~2 minutes and nearly 4GB of peak heap on the second process:

1. **"Warm FASL cache"** step runs SBCL #1 at `--dynamic-space-size 8192` (8GB): `(asdf:load-system :ece)` triggers `load-compiled-zones`, which compiles all `bootstrap/*-zone.lisp` files to `.fasl-cache/bootstrap/*.fasl`, then exits. This step succeeds.
2. **"Mark bootstrap outputs as up-to-date"** step runs `touch bootstrap/*-zone.lisp`, setting the zone sources' mtimes to "now" — strictly newer than the FASLs from step 1. This is load-bearing for `make`'s dependency tracking (prevents `make` from rebuilding zones via `$(ZONE_SENTINEL)` because `src/*.scm` files had the same checkout mtime).
3. **"Build ece binary"** step runs SBCL #2 at `--dynamic-space-size 4096` (4GB): `(asdf:load-system :ece)` again triggers `load-compiled-zones`, which checks `(> (file-write-date source) (file-write-date fasl))` → sees touched sources are newer than cached FASLs → **recompiles all 7 zones from scratch**. The FASLs written by SBCL #1 are thrown away. Compiling 7 zones sequentially at 4GB heap is right at the memory boundary and OOMs non-deterministically — CI crashes on reader-zone, local repro crashes on prelude-zone or succeeds depending on GC timing.

The bug is the mtime race between two consumers with conflicting requirements: `make` wants sources newer-than-or-equal-to targets; `load-compiled-zones` wants sources older-than-or-equal-to FASLs. The CI touch step satisfies the former and breaks the latter.

If we do not fix this, the 4GB ceiling failures will continue non-deterministically, and any future bootstrap expansion will make them worse.

## What Changes

- **MODIFIED** `.github/workflows/test.yml` — the `Mark bootstrap outputs as up-to-date` step now runs **before** `Warm FASL cache`, not after. With this ordering:
  1. Cache is restored (FASLs from a prior run, possibly stale).
  2. Touch sets zone source mtimes to ~now.
  3. Warm FASL cache (SBCL at 8GB) sees source mtimes > stale FASL mtimes (from the restore) → `load-compiled-zones`'s existing mtime check triggers a recompile → writes fresh FASLs with mtimes strictly later than the touched sources.
  4. Build ece binary (SBCL at 4GB) sees fresh FASL mtimes > touched source mtimes → `load-compiled-zones` skips recompilation → `compile-system` runs without the zone-compile memory overhead.
- **NO SOURCE CHANGES** — `src/runtime.lisp`'s `load-compiled-zones` mtime check stays in place. It's load-bearing as a safety net against stale cache restores: if `actions/cache@v4`'s `restore-keys: fasl-` prefix match pulls in FASLs from an older commit, the mtime check detects them as stale and forces a recompile. Removing the check was tried in an earlier iteration of this change and caused an `Unknown label: NIL` error in PR #147's first CI run when warm-cache loaded stale zone FASLs without revalidating.
- **NON-GOAL**: changing the SBCL heap ceiling. The existing 4GB limit stays.
- **NON-GOAL**: removing the CI touch step. It is load-bearing for `make`'s dependency tracking (prevents `$(ZONE_SENTINEL)` from firing on every CI run because `src/*.scm` and `primitives.def` have equal checkout mtimes to bootstrap outputs).
- **NON-GOAL**: rearchitecting `compile-system` or the bootstrap flow.

## Capabilities

### Modified Capabilities
- `bootstrap-compilation` — add a requirement that CI's dedicated `Warm FASL cache` SBCL process may recompile stale bootstrap zones once (as a stale-cache safety net), and that the subsequent `Build ece binary` / `make ece` SBCL process must reuse those fresh FASLs without recompiling. If no such capability exists yet, this change creates one.

## Impact

- **Affected code**: `.github/workflows/test.yml` only. No `src/` or `Makefile` source changes in the final landed version.
- **Affected workflows**: CI build time drops noticeably in the `Build ece binary` step (eliminating a ~2-3 minute zone-recompile pass at 4GB). Total CI time improves by ~2 minutes on a typical run. Local `make ece` is unaffected (no touch step locally).
- **Performance**: peak SBCL heap in the `Build ece binary` step drops from near-4GB-OOM-territory to a low value, because SBCL #2 now just loads cached FASLs and runs `compile-system`.
- **Test plan**: verify the expected log pattern across CI steps, not within a single SBCL image. In `Warm FASL cache`, expect `load-compiled-zones` to compile `bootstrap/*-zone.lisp` files if the restored cache is stale or missing. In the later `Build ece binary` step, confirm there are **zero** `; compiling file "bootstrap/*-zone.lisp"` log lines — SBCL #2 must reuse the freshly-written FASLs. The full CI `make test` suite must still pass.
- **Rollback**: single-commit revert of `.github/workflows/test.yml`.
- **Blocks**: PR #145 (sandbox-live-coding-fixes) and any other open PR, because main is currently red and this is the path back to green.
