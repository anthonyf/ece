## 1. Reproduce locally

- [x] 1.1 Read the CI failure log for PR #145 (run 24340826867) and the main failing run (24321876664). Identify that the two `compiling file` events for `reader-zone.lisp` span different step boundaries (first is the "Warm FASL cache" step, second is the "Build ece binary" step). This contradicted the original "twice in one image" framing.
- [x] 1.2 Run the `share/ece/ece-main.ecec` target's SBCL invocation locally with `ASDF_OUTPUT_TRANSLATIONS` set to the project-local `.fasl-cache/`. Observed: one pass, 7 zone compiles, succeeds at 4GB.
- [x] 1.3 Touch `bootstrap/*-zone.lisp` to simulate the CI touch step, re-run SBCL, and observe: 7 zone recompiles triggered by the mtime check. First run crashed on prelude-zone mid-compile (0-byte FASL corpse). Second run succeeded. **Non-deterministic failure at 4GB confirms the memory ceiling is at the margin.**
- [x] 1.4 Captured logs at `/tmp/claude/repro2.log`, `/tmp/claude/touch-test.log`, `/tmp/claude/fix-test.log`.

## 2. Identify the cause

- [x] 2.1 Bisected via CI log step boundaries: two distinct SBCL processes, not one image with two compiles. First SBCL in warm-cache step compiles zones at 8GB, second SBCL in build-ece step recompiles them at 4GB.
- [x] 2.2 Traced the recompile to `load-compiled-zones` in `src/runtime.lisp:1825-1848`. The function's mtime check `(> (file-write-date path) (file-write-date fasl-path))` fires when the CI touch step makes zone sources newer than cached FASLs.
- [x] 2.3 Confirmed the `Mark bootstrap outputs as up-to-date` step in `.github/workflows/test.yml` is load-bearing for `make`'s dependency tracking (it prevents `$(ZONE_SENTINEL)` from being re-run because `src/*.scm` and `primitives.def` have equal-ish checkout mtimes to bootstrap outputs). So removing the touch is not an option without restructuring make.
- [x] 2.4 Confirmed `.fasl-cache/bootstrap/*-zone.fasl` exists after SBCL #1 in the warm-cache step, but SBCL #2 sees it as "stale" purely because of touched source mtime — the content is still correct.
- [x] 2.5 Verified that no ECE source file (compile-system, compile-file-to-port, SDK files) writes to zone sources or triggers `asdf:load-system :force t`. The mtime check is the ONLY cause of the recompile.
- [x] 2.6 Documented the confirmed root cause in `proposal.md` § Why and this section.

## 3. Implement the fix

- [x] 3.1 First attempt: modified `src/runtime.lisp` `load-compiled-zones` to drop the mtime check entirely and modified `Makefile` `$(ZONE_SENTINEL)` to `rm -f .fasl-cache/bootstrap/*-zone.fasl`. Locally verified to pass. Pushed as PR #147 commit `516e647`. **Failed in CI**: `actions/cache@v4`'s `restore-keys: fasl-` prefix match restored FASLs from commit `d8a920c4...` (not an exact match for PR #147's source hash), and without the mtime check warm-cache loaded those stale zone FASLs as-is. `compile-system` then errored at runtime with `Unknown label: NIL` inside `strip-source-locations` — the FASL was incompatible with the newly-compiled runtime. **Reverted `src/runtime.lisp` and `Makefile` changes.**
- [x] 3.2 Second attempt: revert the source changes. Instead, reorder `.github/workflows/test.yml` so `Mark bootstrap outputs as up-to-date` runs **before** `Warm FASL cache`. The mtime check in `load-compiled-zones` stays as a stale-cache safety net. With the reordering:
  - Touch sets source mtimes to ~T1.
  - Warm FASL cache at 8GB: asdf:load-system sees touched sources newer than restored (stale) FASLs → mtime check triggers recompile → writes fresh FASLs at ~T2 > T1.
  - Build ece binary at 4GB: sees fresh FASL mtimes > touched source mtimes → mtime check skips recompile → compile-system runs at low heap.
- [ ] 3.3 CI verification: push the reordering, confirm CI passes and that `Build ece binary` step does not show zone `compiling file` events (it loads cached FASLs).

## 4. Verify on CI

- [ ] 4.1 Push to a branch, open a PR, observe CI pass. Grep the CI log for the `; compiling file "bootstrap/*-zone.lisp"` lines and confirm each zone appears at most once per SBCL image.
- [ ] 4.2 Compare CI `make ece` wall-clock time before vs. after the fix. Record the delta in the PR description.

## 5. Follow-up tracking

- [ ] 5.1 If the investigation reveals a systemic issue beyond just the double compile (e.g., `prelude.scm` / `reader-zone.lisp` is legitimately too large and needs splitting), open a separate OpenSpec proposal for that work and reference it in this change's archive summary.
- [ ] 5.2 Confirm `Makefile` still uses `--dynamic-space-size 4096` (we never shipped the bump). No revert needed.
