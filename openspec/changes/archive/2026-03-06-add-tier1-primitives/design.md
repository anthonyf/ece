## Context

ECE registers primitives in two ways: direct CL function mappings via the primitive alist, and custom wrapper functions registered via `dolist`. All new primitives here map cleanly to CL built-ins or simple wrappers.

## Goals / Non-Goals

**Goals:**
- Add `error`, `assoc`, `member`, `list-ref`, `list-tail`, and string comparison predicates
- All primitives callable from ECE programs immediately
- Full test coverage for each

**Non-Goals:**
- Structured exception handling (`guard`, `with-exception-handler`) — future work
- `error` with irritant objects (R7RS full form) — just message string for now

## Decisions

### error
Use CL's `(error message)` directly. This signals a CL `simple-error` condition, which `try-eval` already catches. Map as a direct primitive: `(error . cl:error)`. This gives ECE programs the ability to signal errors that interoperate with the existing `try-eval` mechanism.

### assoc and member
CL has `assoc` and `member` but they use `:test` keyword args. ECE's `assoc` should use `equal?` semantics (structural equality via `equal`). Map directly: `(assoc . assoc)` and `(member . member)` — CL defaults to `eql` which works for symbols and numbers. This matches Scheme's `assq`/`memq` behavior. For full `equal?`-based versions, we'd need wrappers, but `eql` semantics cover the common case (symbol keys, number values).

**Decision**: Use CL's default `eql` test. This matches `assq`/`memq` and covers the most common use case. If `equal?`-based versions are needed later, add `assoc-equal` or parameterize.

### list-ref and list-tail
`list-ref` maps to CL's `nth`, and `list-tail` maps to `nthcdr`. Direct primitive mappings.

### String comparisons
`string=?` maps to `string=`, `string<?` to `string<`, `string>?` to `string>`, `string<=?` to `string<=`, `string>=?` to `string>=`. All direct CL mappings.

## Risks / Trade-offs

- **assoc/member use eql not equal**: Programs comparing string keys won't match with `assoc`. This is the same as Scheme's `assq`/`memq`. Acceptable for now; `assoc` with `equal` semantics can be added later if needed.
- **error is simple string-only**: R7RS `error` takes a message and irritant objects. Our version just takes a string. Sufficient for current needs.
