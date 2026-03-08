## Context

ECE has `string-split` but no `string-join` (its complement), and no substring search. Hash tables have `hash-keys` but no `hash-values`. All three are straightforward CL wrapper primitives.

## Goals / Non-Goals

**Goals:**
- Add three utility primitives following existing patterns in ece.lisp

**Non-Goals:**
- Regex or pattern matching

## Decisions

### All three implemented as CL-side primitives
These are thin wrappers over CL builtins (`search`, `format`, `mapcar`), so they belong in ece.lisp alongside existing primitives rather than in prelude.scm.

- `string-contains?` wraps CL `search` — returns boolean (not index)
- `string-join` wraps CL `format` with `~{~A~^sep~}` pattern — takes separator and list
- `hash-values` maps over internal alist representation extracting cdr values

## Risks / Trade-offs

None — trivial additions following established patterns.
