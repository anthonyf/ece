## Context

`let-syntax` and `letrec-syntax` introduce locally-scoped macro bindings. ECE's macro table (`get-macro`/`set-macro!`) is currently global. We need a way to temporarily bind macros for the duration of a body.

## Goals / Non-Goals

**Goals:**
- `(let-syntax ((name transformer) ...) body ...)` binds macros locally
- `(letrec-syntax ((name transformer) ...) body ...)` same, with mutual visibility
- Pass all 5 remaining pitfall tests

**Non-Goals:**
- Full hygiene for let-syntax introduced bindings (gensym-based is sufficient)
- Optimizing macro lookup (global table with save/restore is fine)

## Decisions

### Implement as macros that save/restore the global macro table

`let-syntax` expands to code that:
1. Saves the current macro bindings for each name
2. Installs the new transformers via `define-syntax` (or directly via `set-macro!`)
3. Evaluates the body
4. Restores the original bindings

This is the simplest approach that works with ECE's existing global macro table. Since macro expansion happens at compile time, the save/restore happens during compilation — there's no runtime overhead.

Actually, there's a subtlety: `define-syntax` expands to `define-macro`, which is processed by the compiler at compile time. So `let-syntax` needs to expand to a form that the compiler processes correctly — it can't just be a runtime save/restore.

Better approach: `let-syntax` expands to a `begin` that:
1. Saves current macros
2. Defines new macros (via `define-macro`)
3. Includes the body forms
4. Restores original macros

But `begin` at the compiler level processes all forms sequentially, and the define-macro forms register the macros at compile time. The body forms are compiled with the new macros in scope. Then the restore happens after the body.

This works because `mc-compile-begin` compiles forms sequentially — the define-macro is processed before the body forms.

## Risks / Trade-offs

**[Global table mutation]** → The save/restore approach temporarily mutates the global macro table. This is safe because compilation is single-threaded and the restore always runs.
