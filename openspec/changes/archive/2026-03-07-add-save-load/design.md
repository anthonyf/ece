## Context

ECE continuations are stored as `(continuation <stack> <conts>)` where primitives are represented by symbol (e.g., `(primitive ece-display)`) rather than function objects. This means continuations are already plain s-expressions with no opaque objects — they can be serialized with standard `write`/`read`.

Hash tables use the s-expression form `(:hash-table (k . v) ...)` which is also fully serializable.

## Goals / Non-Goals

**Goals:**
- Add `save-continuation!` to write any ECE value (including continuations) to a file.
- Add `load-continuation` to read a saved value back from a file.
- Update the roadmap to reflect current progress.

**Non-Goals:**
- No slot management, autosave, or file listing.
- No encryption or compression.
- No special handling of open file handles or streams in continuations.

## Decisions

### Decision 1: Use CL's `write` with `*print-circle*` for serialization
CL's `write` with `*print-circle*` set to `t` handles shared structure and circular references using `#n=` / `#n#` notation. CL's `read` natively understands this notation. This is the standard approach and requires no custom serializer.

Alternative: Custom serializer — unnecessary complexity since the built-in mechanism handles all our data types.

### Decision 2: Use `prin1-to-string` style output (not `princ`)
`write` with `:readably t` ensures strings are quoted, symbols are properly escaped, and the output can be read back unambiguously. `princ`-style output would lose type information.

### Decision 3: Save single value per file
`save-continuation!` writes exactly one s-expression to the file. If a program needs to save multiple values, it can bundle them into a list or hash table before saving. This keeps the API simple.

### Decision 4: Read with ECE readtable
`load-continuation` reads with `*ece-readtable*` active so hash table literals (`{}`) and quasiquote syntax are properly restored. Package is bound to `:ece` so symbols resolve correctly.

## Risks / Trade-offs

- [Continuation captures mutable state by reference] → Saving captures the continuation's stack/conts at save time. Mutable variables in the environment are NOT captured — only the continuation's execution state. This is inherent to how `call/cc` works and is documented, not a bug.
- [Large continuations] → Deep call stacks produce large save files. Acceptable for typical use cases which have shallow stacks.
