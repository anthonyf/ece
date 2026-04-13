## 1. Reproduce the double compile locally

- [ ] 1.1 Clean state: `rm -rf .fasl-cache/ share/ece/ece-main.ecec` and record the timestamp of `bootstrap/reader-zone.lisp`.
- [ ] 1.2 Run the exact command from `Makefile:28-33` (the `share/ece/ece-main.ecec` target's SBCL invocation) in a terminal, with SBCL's `*compile-verbose*` and `*load-verbose*` both set to `t`, and capture the full output.
- [ ] 1.3 Confirm that the output contains `; compiling file "bootstrap/reader-zone.lisp"` at least twice. If not, try replicating CI conditions: `touch bootstrap/*-zone.lisp` before the run (CI does this at `.github/workflows/test.yml:59-64`). Repeat until the double compile is reliably reproducible.
- [ ] 1.4 Record the wall-clock delta between the two `; compiling file` lines and whether any GC happens between them. Save the captured log to `.tmp/double-compile.log` (gitignored) for reference.

## 2. Identify the cause

- [ ] 2.1 Bisect: comment out the second `--eval` in the Makefile target (the `ece:evaluate` call). Does the double compile still happen? If yes, the cause is inside `asdf:load-system`; if no, it is inside `compile-system` or its callees.
- [ ] 2.2 If the cause is inside `compile-system`, grep ECE source for `load-system`, `compile-file`, and `asdf:` calls that fire during compile-system. Trace what touches zone files.
- [ ] 2.3 If the cause is inside `asdf:load-system` alone, instrument with `(trace asdf:operate asdf:compile-file*)` before the second `--eval` and observe what forces a recompile.
- [ ] 2.4 Check the FASL cache state between the two compiles. Does `.fasl-cache/bootstrap/reader-zone.fasl` exist after the first compile? If yes, why does ASDF decide it's stale for the second?
- [ ] 2.5 Specifically validate or rule out each hypothesis from `design.md` § Context (ASDF freshness re-check, `compile-system` side-effect, output-translation mismatch, `*features*` change).
- [ ] 2.6 Write the confirmed cause and supporting evidence into `design.md` under a new `## Root Cause (confirmed)` section before implementing the fix.

## 3. Implement the fix

- [ ] 3.1 Based on the confirmed cause, apply the smallest scoped change that eliminates the second compile. Examples of scope: removing a `:force t` argument, fixing an `ASDF_OUTPUT_TRANSLATIONS` inconsistency, hoisting a pushnew out of the initialization path, skipping an unnecessary `load-system` reinvocation.
- [ ] 3.2 Confirm the fix locally: re-run the invocation from task 1.2 and verify `; compiling file "bootstrap/reader-zone.lisp"` appears **at most once** in the output.
- [ ] 3.3 Run `make ece` on a clean cache with the existing 4GB ceiling (`Makefile:30` stays at `--dynamic-space-size 4096`). Confirm it succeeds without `Heap exhausted`.
- [ ] 3.4 Run `make test` (full suite: `test-rove test-ece test-wasm test-conformance test-golden test-web-server test-web-apps`) to confirm no regression.

## 4. Verify on CI

- [ ] 4.1 Push to a branch, open a PR, observe CI pass. Grep the CI log for the `; compiling file "bootstrap/*-zone.lisp"` lines and confirm each zone appears at most once per SBCL image.
- [ ] 4.2 Compare CI `make ece` wall-clock time before vs. after the fix. Record the delta in the PR description.

## 5. Follow-up tracking

- [ ] 5.1 If the investigation reveals a systemic issue beyond just the double compile (e.g., `prelude.scm` / `reader-zone.lisp` is legitimately too large and needs splitting), open a separate OpenSpec proposal for that work and reference it in this change's archive summary.
- [ ] 5.2 Confirm `Makefile` still uses `--dynamic-space-size 4096` (we never shipped the bump). No revert needed.
