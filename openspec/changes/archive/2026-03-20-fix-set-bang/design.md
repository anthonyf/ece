## Context

ECE's compiler recognizes `set` as the assignment special form (line 132 of `compiler.scm`: `(mc-tagged-list? expr 'set)`). R7RS uses `set!`. The `!` suffix is a Scheme convention indicating mutation. This is a simple rename with no semantic change.

## Goals / Non-Goals

**Goals:**
- Rename `set` → `set!` as the assignment special form
- Update all ECE source files and rebuild bootstrap
- Update the spec to reflect the new name

**Non-Goals:**
- Changing assignment semantics (they're already correct)
- Adding a compatibility alias for old `set` (clean break)

## Decisions

### 1. Clean rename, no alias

Replace `set` with `set!` everywhere. No backward compatibility shim. ECE has no external users yet, so a clean break is simpler.

### 2. No conflict with CL

`set!` contains `!` which is a valid identifier character in both ECE and CL. The ECE reader already handles `!` in symbols (e.g., `set-car!`, `define-variable!`). In CL, the symbol `set!` is interned as `ECE::|set!|` — distinct from `CL:SET`. No naming conflict.

## Risks / Trade-offs

- **[Low risk]** Straightforward find-and-replace in ~27 locations across source files, plus compiler special form check. Bootstrap rebuild required.
