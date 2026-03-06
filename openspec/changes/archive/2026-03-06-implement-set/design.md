## Context

The evaluator already has `assignment-p` predicate and `set` in `*special-forms*`, but no continuation handlers. The frame-based environment supports `define-variable!` (first frame only). `set!` needs `set-variable-value!` which scans all frames to find and update an existing binding, erroring if unbound.

## Goals / Non-Goals

**Goals:**
- Add `set-variable-value!` that scans all frames to update an existing binding
- Implement `ev-assignment` and `ev-assignment-assign` continuation handlers following SICP's pattern
- `set!` signals an error for unbound variables (unlike `define` which creates new bindings)

**Non-Goals:**
- Renaming `set` to `set!` in the special forms list (CL's reader handles `!` fine, but the existing `set` name works)

## Decisions

**Follow SICP's `ev-assignment` exactly**: The handler is structurally identical to `ev-define` — save the variable name, env, and conts; evaluate the value expression; then restore and call `set-variable-value!`. The only difference is calling `set-variable-value!` instead of `define-variable!`.

**`set-variable-value!` scans all frames**: Unlike `define-variable!` which only looks at the first frame, `set-variable-value!` walks the entire environment chain. If the variable is found in any frame, it updates the value in place. If not found in any frame, it signals an error.

**Use existing `set` name**: The predicate `assignment-p` already checks for `(eq (car expr) 'set)`. We keep this — ECE uses `set` rather than Scheme's `set!` since the `!` convention is cosmetic.

## Risks / Trade-offs

- [No new risks] → This is a straightforward addition following established patterns (`ev-define` is the template)
