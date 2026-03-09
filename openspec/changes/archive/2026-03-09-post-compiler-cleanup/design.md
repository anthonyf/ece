## Context

ECE recently replaced its SICP-style explicit control interpreter with a SICP 5.5 compiler. The old interpreter was kept "for reference" during development but is now dead code. The codebase has ~1924 lines in `src/ece.lisp`, of which ~524 are unused.

## Goals / Non-Goals

**Goals:**
- Remove all dead code left over from the interpreter-to-compiler transition
- Simplify redundant functions (`ece-load` duplicating `compile-file-ece`)
- Fix outdated comments and documentation
- All existing tests pass unchanged — zero behavioral changes

**Non-Goals:**
- Refactoring or optimizing live compiler/executor code
- Adding new features or capabilities
- Changing the public API (`evaluate`, `repl`, etc.)

## Decisions

### 1. Remove `evaluate-interpreted` entirely (don't keep behind a feature flag)

**Rationale:** It's 500 lines that nothing calls. Git history preserves it if ever needed. Keeping dead code "for reference" is a maintenance burden — it can drift out of sync with the actual implementation and confuse readers.

### 2. Remove standalone `assemble` but keep `assemble-into-global`

**Rationale:** `assemble` returns a local vector + label table, which was the original design before the global accumulator pattern. It's never called. `assemble-into-global` is the only assembler in use.

### 3. Remove runtime macro storage from `compile-define-macro`

**Rationale:** The line `(define-variable! variable (list 'macro ...) *global-env*)` writes a value that nothing reads. The compiler looks up macros exclusively from `*compile-time-macros*`. The only code that dispatched on `'macro` tagged values was the old interpreter's `:ev-appl-did-operator` handler, which is being removed.

### 4. Simplify `ece-load` to call `compile-file-ece`

**Rationale:** Both functions do the same thing — read forms from a file and call `compile-and-go` on each. `ece-load` should delegate to `compile-file-ece` rather than reimplementing the read loop.

### 5. Update README to mention "compiler" rather than "evaluator"

**Rationale:** The architecture fundamentally changed. ECE compiles to register machine instructions, then executes them. The README should reflect this.

## Risks / Trade-offs

- **[Risk] Removing `evaluate-interpreted` loses quick reference** → Mitigated by git history. The archived change at `openspec/changes/archive/2026-03-09-add-compiler/` also documents the transition.
- **[Risk] `ece-load` simplification could change behavior** → Both functions are identical in effect (read + compile-and-go). Tests cover file loading.
