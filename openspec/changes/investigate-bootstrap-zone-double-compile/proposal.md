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
- `bootstrap-compilation` (or whichever existing capability owns the bootstrap-zone compile flow) — add a requirement that each bootstrap zone is compiled at most once per SBCL image during `make ece`. If no such capability exists yet, create one.

## Impact

- **Affected code**: likely `src/` files that implement `compile-system` and its interaction with ASDF-managed zone FASLs, plus possibly the Makefile's `ece-main.ecec` target if the fix requires separating the two SBCL invocations. Scope should be small once the cause is identified.
- **Affected workflows**: CI build time should drop noticeably (eliminating a ~20s + some-minutes-of-second-pass compile). Local `make ece` also benefits.
- **Performance**: peak SBCL heap during `make ece` should drop back below the 4GB ceiling once the second compile is eliminated, and CI goes green at the existing ceiling.
- **Test plan**: reproduce the double-compile locally with `*compile-verbose*` and `*load-verbose*` set to `t`, or by running the compile-system invocation manually and watching for `; compiling file "bootstrap/reader-zone.lisp"` appearing twice in one image. After the fix, confirm it appears exactly once. Run full `make test` to confirm no regression.
- **Rollback**: single-commit revert.
- **Blocks**: PR #145 (sandbox-live-coding-fixes) and any other open PR, because main is currently red and this is the path back to green.
