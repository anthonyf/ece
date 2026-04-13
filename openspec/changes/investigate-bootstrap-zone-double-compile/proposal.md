## Why

Main has been red since PR #144 with SBCL `Heap exhausted during garbage collection` while compiling `bootstrap/reader-zone.lisp` during `make ece`. A ceiling bump from 4GB to 8GB was considered and rejected as a masking fix: it does not address the real problem, and it shifts the ceiling without buying time against future bootstrap expansion.

The CI failure log shows `bootstrap/reader-zone.lisp` being compiled **twice in the same SBCL image** during the `share/ece/ece-main.ecec` target (Makefile:28-33), roughly three minutes apart:

```
01:49:03 ; compiling file "bootstrap/reader-zone.lisp"
01:49:23 ; wrote .fasl-cache/bootstrap/reader-zone.fasl     ← 20s, first pass
01:52:00 ; compiling file "bootstrap/reader-zone.lisp"      ← second pass, 3 min later
01:52:13 Heap exhausted, game over.
```

That is duplicated work — the zone doesn't change between the first and second compile. The first pass runs during `(asdf:load-system :ece)`; the second happens somewhere inside `(ece:evaluate (compile-system ...))`. Compiling `reader-zone.lisp` once costs roughly a gigabyte of peak SBCL heap (constraint-propagation passes over a 376k-line generated file). Compiling it twice with no incremental state release between passes is what pushes the image over the ceiling, regardless of whether the ceiling is 4GB or 8GB.

If we do not investigate this, we will keep raising the ceiling until we run out of runner memory — each migration that moves more work into ECE zones pushes peak heap further up, and each fix buys less time than the last.

## What Changes

- **INVESTIGATE** why `compile-system` triggers a second compilation of `bootstrap/*-zone.lisp` files when `asdf:load-system :ece` has already compiled them in the same SBCL image. Suspects: ASDF re-checking freshness, ECE's compiler writing over the zone files as a side effect of `(compile-system ...)` via `ece:evaluate`, or a cache-invalidation interaction with the `ASDF_OUTPUT_TRANSLATIONS` redirect that makes ASDF treat the FASL as stale on the second load.
- **FIX** the double-compile so that a fresh SBCL image running `make ece` compiles each `*-zone.lisp` at most once.
- **NON-GOAL**: changing the SBCL heap ceiling. This proposal is about correctness of work (stop doing duplicate compiles), not about memory ceiling. After the fix, the existing 4GB ceiling should remain fine.
- **NON-GOAL**: rearchitecting `compile-system` or the bootstrap flow. The scope is finding and removing the duplicate invocation.

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
