## Context

Post `ece-sdk-toolchain`, ECE has:

- `src/test-lib.scm` — user-facing assertion API, parameter-based state (new, installed to `share/ece/`).
- `tests/ece/test-framework.scm` — ECE's own test framework, global-mutation state (old, in-tree only).
- `tests/ece/run-*.scm` — orchestration scripts loading dozens of `test-*.scm` files sequentially, sharing global state.
- `tests/test-counts.json` + `scripts/check-test-counts.sh` + `make update-test-counts` — a baseline-count regression gate that requires manual update every time tests are added.

Both frameworks expose the same public API (`test`, `assert-equal`, `assert-true`, `assert-false`, `assert-error`, `assert-error-message`, `run-tests`) so dropping one in favor of the other is mostly mechanical. The split was a historical accident — ECE's own tests were written before the user-facing API shipped.

The baseline-count gate is ECE-specific; no mainstream test framework (pytest, Jest, Mocha, Go, Rust, JUnit) maintains a separate count file. They rely on runner hygiene instead (error on zero-tests-collected, exit non-zero on failure, explicit skip counts).

## Goals / Non-Goals

**Goals:**
- One test framework file (`src/ece-unit.scm`), user-facing, shipped in `share/ece/`.
- ECE's own tests run via `bin/ece-test` — same tool users use for their own projects.
- `tests/ece/` organized by runtime eligibility (`common/` runs anywhere, `cl-only/` needs CL primitives).
- Runner hygiene: `ece-test` exits non-zero on zero tests collected, reports `collected/ran/passed/failed`.
- `--filter PATTERN` for running a subset of tests by name substring.
- No baseline-count state file; runner exit codes are the signal.
- WASM test path updated to new framework file + directory glob.

**Non-Goals:**
- Regex or glob patterns in `--filter` (substring match only).
- pytest-style expressions (`"parse and not slow"`) or tags.
- Multi-suite aggregation beyond per-directory rollups.
- Per-test timing, coverage, or performance reporting.
- Renaming test files or changing test content beyond what directory moves require.
- Parallel test execution.

## Decisions

### D1. File name: `src/ece-unit.scm`

Rename `src/test-lib.scm` → `src/ece-unit.scm` and absorb `tests/ece/test-framework.scm`.

**Why `ece-unit`:**
- Matches the `ece-*` naming pattern of other SDK files (`ece-main.scm`, `ece-build.scm`, `ece-test.scm`), which all get deployed to `$PREFIX/share/ece/`.
- Short and signals "ECE unit testing" in prose.
- Parallels `ece-test` (the runner) with `ece-unit` (the authoring API).

**Overloading concern:** ECE has `src/compilation-unit.scm` (compiler module; "unit" = translation unit). Different domain; the `ece-` prefix disambiguates. Java handled the same overlap fine.

**Alternatives considered:**
- `ece-testing.scm` — avoids "unit" overload but longer.
- `test-lib.scm` (current) — generic, doesn't match the `ece-*` SDK convention.
- `ece-unit-test.scm` — longest, most explicit.

### D2. Directory structure: `common/` + `cl-only/`

```
tests/ece/
├── common/                 # 22 files, runs on any runtime
│   ├── test-arithmetic.scm
│   ├── test-lists.scm
│   └── ...
└── cl-only/                # files that need CL-specific primitives
    ├── test-compilation-units.scm
    ├── test-serialization.scm
    ├── test-source-locations.scm
    ├── test-ece-main-args.scm
    └── test-ece-test-runner.scm
```

**Why directories:**
- Zero new syntax. Just `mv`.
- ece-test already walks directories.
- Each positional arg IS a partition. No new noun needed.
- WASM bundling becomes a trivial `$(wildcard tests/ece/common/test-*.scm)`.

**Alternatives considered:**
- In-file suite declarations (`(suite "..." ...)`) — extra syntax, nesting level.
- Filename convention (`test-cl-*.scm` for CL-only) — renames many files, fragile.
- Manifest files — yet another format to maintain.

### D3. No new concept above the file

`ece-test` takes paths as positional args, reports per-directory rollups, and a total. No word "suite" / "group" / "tier". The output shows what was passed in; the structure speaks for itself.

```
$ ece-test tests/ece/common tests/ece/cl-only
tests/ece/common: 572 passed, 0 failed (22 files)
tests/ece/cl-only: 179 passed, 0 failed (5 files)
751 collected, 751 ran, 751 passed, 0 failed
```

### D4. Drop baseline counts

Delete `tests/test-counts.json`, `scripts/check-test-counts.sh`, and `make update-test-counts`. Runner hygiene replaces them:

1. `ece-test` reports `collected`, `ran`, `passed`, `failed` counts.
2. `ece-test` exits **2** if zero tests are collected across all paths.
3. `ece-test` exits **1** if any test fails or any file fails to load.
4. `collected != ran` is visible in output (indicates skips or filtering).

**What this loses:** detection of drive-by test deletion (someone intentionally removing a passing test). That's caught by code review and coverage tools elsewhere; not worth the maintenance friction.

**Alternatives considered:**
- Keep `test-counts.json` as-is — current friction (manual updates, broken `update-test-counts` target for WASM).
- Derive count from `grep -c '(test "'` on source files — works for literal top-level registrations but breaks if tests are registered dynamically. Static count also doesn't catch "tests skipped at runtime" (unlike registered/ran tracking).

### D5. `--filter PATTERN` — substring match

```scheme
ece-test --filter string tests/ece/common/
; runs only tests whose name contains "string"
```

**Why substring:**
- Matches pytest's `-k` default (before expressions).
- 80% of "run the test I'm working on" use case is covered.
- ~15 lines of code using existing `string-contains?`.
- Multiple `--filter` flags compose with OR.
- Empty string matches all (consistent with substring semantics).
- Case-sensitive (test names are identifiers).

**Alternatives considered:**
- Regex — requires regex engine (new capability).
- Glob — needs mini matcher, less expressive than substring for the common case.
- pytest-style expressions — requires expression parser.

Growth path: add `--filter-regex` or expression grammar later if substring proves insufficient.

### D6. Multiple `--filter` = OR

```
ece-test --filter parse --filter lex tests/
; matches test names containing "parse" OR "lex"
```

**Why OR:** matches user expectation ("run tests matching X *or* Y"). AND is achievable by using a more-specific single pattern.

### D7. Zero tests collected = exit 2

If `ece-test` walks the given paths and registers zero tests, exit code is **2** with a clear message. This catches:
- Bad paths (typos, directories that don't exist or are empty).
- `--filter` that matches nothing.
- Rename-outs (test files renamed away from the `test-*.scm` pattern).

**Alternative considered:** exit 0 with "0 tests" message. Rejected — silently succeeding when nothing ran hides configuration mistakes (pytest uses exit 5 for this; we use 2 since we already use 2 for "runner error").

### D8. Filter doesn't affect the `collected` count

The `collected` count reflects all tests registered; `ran` reflects post-filter. This lets users see what filtering did:

```
$ ece-test --filter string tests/ece/common/
...
751 collected, 42 ran, 42 passed, 0 failed
```

If filter matched nothing (42→0), zero-tests-collected check does NOT fire — collected was 751. A separate exit behavior for "filter matched nothing" is NOT added in this change; user sees "0 ran" in output.

### D9. Cross-file helpers must become shared modules

Audit finding: if any `test-*.scm` file references helpers defined in another, per-file isolation breaks it. Mitigation: move shared helpers into `tests/ece/common/helpers-*.scm` files, loaded via explicit `(load "helpers-...")` at the top of the files that use them. Not named `test-*` so ece-test doesn't discover them as test files.

### D10. Global-state tests need spike first

Three files exercise global ECE state:
- `test-compilation-units.scm` — uses `compile-form`, creates/mutates compilation spaces.
- `test-serialization.scm` — uses continuation save/load, exercises env frames.
- `test-source-locations.scm` — uses `compile-file`, registers source-maps globally.

Under the old `run-all.scm` model, these accumulated state in the shared env. Under ece-test's per-file isolation, each runs in a fresh state. **Risk:** tests may fail because they rely on state set by earlier tests in the run. Mitigation: run these three files first as a canary before moving the rest.

### D11. WASM path: glob + bundle

Current:
```makefile
WASM_TEST_SRCS := $(shell grep -o '"[^"]*"' tests/ece/run-common.scm | tr -d '"') wasm/wasm-test-runner.scm
```

New:
```makefile
WASM_TEST_SRCS := src/ece-unit.scm $(wildcard tests/ece/common/test-*.scm) wasm/wasm-test-runner.scm
```

The WASM runner cats these into one file, compiles with `compile-file`, runs via node. No `run-wasm.scm` intermediary needed; the Makefile is the manifest.

### D12. `wasm-test-runner.scm` shape

This file still owns the "invoke `run-tests` and print results" entry point for the WASM path. It calls `run-tests` (now exported from `ece-unit.scm`) and pretty-prints the result triple. Single file, ~20 lines.

### D13. `ece-unit.scm` API stays stable

The user-facing API (`test`, `assert-equal`, `assert-true`, `assert-false`, `assert-error`, `assert-error-message`, `run-tests`) is unchanged. `run-tests` already returns `(list passes failures failure-msgs per-test-output)` post-`ece-sdk-toolchain`. We extend it to include `collected` as a leading element:

```
(run-tests)  →  (list collected ran passes failures failure-msgs per-test-output)
```

or, to avoid breaking callers (WASM test runner) — add a new function `run-tests-verbose` that returns the extended tuple, keep `run-tests` at the 4-element shape. TBD during implementation.

## Risks / Trade-offs

- **[Risk] Per-file isolation breaks tests that rely on global mutation.** → Mitigation: canary the three risky files first (D10); fix any cross-file dependencies by extracting helpers (D9); accept that a small number of files may need rewriting.
- **[Risk] Output format change breaks downstream parsers.** The Makefile grep for "0 failed" needs the new format to contain that exact string. → Mitigation: keep "N passed, N failed" line in output; add `collected/ran` as a separate line.
- **[Risk] Dropping baseline lets silent deletions through.** → Accepted trade-off. Matches industry practice; code review catches drive-bys.
- **[Risk] `--filter` regex request creeps in.** → Mitigation: explicit non-goal in this change; keep substring-only for v1.
- **[Risk] WASM bundle generation becomes fragile if common/ layout changes.** → Mitigation: wildcard glob in Makefile; tests documented to live in common/ or cl-only/.
- **[Trade-off] Moving files creates large git churn in one commit.** → Accepted. Git's rename detection handles it.
- **[Trade-off] `ece-test` output format changes.** → Visible, one-time migration. CI greps in `Makefile` updated in same commit.

## Migration Plan

1. **Rename the framework:** `git mv src/test-lib.scm src/ece-unit.scm`. Update references in `Makefile` (install target), `scripts/build-ece-binary.lisp`, any tests that loaded it by name.
2. **Extend `ece-unit.scm`:** add `collected` tracking. Ensure API stable.
3. **Update `ece-test`:** add `--filter PATTERN` flag, `collected/ran` reporting, exit-2-on-zero.
4. **Spike canary:** move `test-compilation-units.scm`, `test-serialization.scm`, `test-source-locations.scm` to `tests/ece/cl-only/`, run via `bin/ece-test` — confirm they pass under per-file isolation. Fix or flag any breakage.
5. **Move files:** `git mv tests/ece/test-*.scm tests/ece/common/` (except the CL-only ones).
6. **Audit cross-file deps:** grep for helper references across files; extract to `helpers-*.scm` modules where needed.
7. **Delete:** `tests/ece/test-framework.scm`, `tests/ece/run-all.scm`, `tests/ece/run-common.scm`, `tests/ece/run-cl.scm`, `tests/ece/run-wasm.scm`.
8. **Update Makefile:** `test-ece` → `bin/ece-test tests/ece/common tests/ece/cl-only`. `test-wasm` → glob `tests/ece/common/`. Remove `check-test-counts` and `update-test-counts` targets.
9. **Delete baseline:** `tests/test-counts.json`, `scripts/check-test-counts.sh`.
10. **Update WASM runner:** `wasm/wasm-test-runner.scm` calls `run-tests` from `ece-unit.scm`; bundle includes `src/ece-unit.scm`.
11. **Un-gimp integration tests:** `tests/ece/cl-only/test-ece-test-runner.scm` can now directly test `run-one-test-file` without dual-framework conflict.
12. **Run all suites:** verify counts, no regressions.
13. **Update README:** mention `ece-test --filter`; remove references to `make update-test-counts`.

**Rollback strategy:** single commit / PR. Revert if canary fails or counts drift unexpectedly.

## Open Questions

- **Q1.** Should `run-tests` return shape change (D13) — extend to 6-element tuple, or add `run-tests-verbose`? Lean: extend, update WASM runner in same change (single caller).
- **Q2.** Do any current `test-*.scm` files share helpers via global definitions? (Audit-required before implementation.)
- **Q3.** What's the actual count split between `common/` and `cl-only/`? (Spike-required; informs the CI grep format.)
- **Q4.** Does `test-output-capture.scm` rebind `current-output-port` in ways that conflict with `ece-test`'s own rebinding? (Spike-required.)
- **Q5.** `--filter PATTERN` (long) and `-k PATTERN` (pytest-style short)? Lean: just `--filter` for v1; add `-k` as alias if requested.
