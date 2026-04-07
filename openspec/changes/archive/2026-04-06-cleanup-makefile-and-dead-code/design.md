## Context

A code review flagged several low-effort issues: duplicated Makefile targets, a `$(shell mktemp -d)` that runs unconditionally at parse time, and dead legacy parameter code in runtime.lisp. All are safe, surgical changes.

## Goals / Non-Goals

**Goals:**
- Eliminate duplicated Makefile targets (`run`/`repl`, `clean`/`clean-fasl`)
- Stop creating orphan temp dirs on unrelated `make` invocations
- Remove dead legacy parameter code from runtime.lisp

**Non-Goals:**
- Expanding `clean` to delete additional artifacts (bin/, .tmp/, etc.)
- Refactoring other Makefile targets
- Touching any other runtime.lisp code

## Decisions

### 1. `run` delegates to `repl`

`run: repl` with no recipe. Simple prerequisite delegation — Make runs the `repl` recipe when `run` is invoked.

### 2. `clean-fasl` delegates to `clean`

`clean-fasl: clean` with no recipe. If `clean` later gains broader scope (deleting more artifacts), `clean-fasl` remains a focused alias.

### 3. `TEST_OUTPUT_DIR` moves to a fixed path

Replace `TEST_OUTPUT_DIR := $(shell mktemp -d)` with `TEST_OUTPUT_DIR := .tmp/test-output`. Add `mkdir -p $(TEST_OUTPUT_DIR)` at the start of the `test-rove` recipe (the first test target). This avoids parse-time side effects while keeping output captured. Add `.tmp/test-output/` to `.gitignore` if not already covered.

Alternative considered: using `=` (lazy expansion) with `mktemp -d`. Rejected because `=` re-evaluates on every reference, creating multiple temp dirs. A fixed path is simpler and predictable.

### 4. Remove legacy parameter code

Delete `*parameter-table*`, `*parameter-counter*`, and `ece-make-parameter-legacy`. The env-stored-parameters migration completed (commit ec6981d, 2026-03-19). `ece-make-parameter-legacy` has zero call sites. The `apply-primitive-procedure` symbol-dispatch path that reads `*parameter-table*` is also unreachable with current code but is left alone — it handles other symbol-keyed primitives and is a separate concern.

## Risks / Trade-offs

- **Risk**: Removing legacy parameter code could break loading very old `.ecec` files that still contain `(primitive PARAMN)` tags.
  → **Mitigation**: Verified no such files exist in the repo. `make bootstrap` regenerates all `.ecec` files from `.scm` sources. The migration is complete.

- **Risk**: Fixed `TEST_OUTPUT_DIR` path could collide between parallel `make test` runs.
  → **Mitigation**: Parallel test runs are not a supported workflow. Single-user development only.
