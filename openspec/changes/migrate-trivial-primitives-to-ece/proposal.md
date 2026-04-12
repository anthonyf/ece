## Why

Stage 1 coverage expansion (PR #143) put all bootstrap spaces in compiled zones, eliminating the interpreter overhead that previously made "everything in ECE" too slow. We can now move trivial primitives — pure list accessors, constructors, and predicates — from `src/primitives.scm` to `src/prelude.scm` without measurable performance impact, because the ECE definitions get compiled to native CL via the same codegen as the rest of the prelude. Each primitive moved is one less function to port to WAT in Phase 2 (the WASM runtime), shrinking the portability surface area.

The criterion for "movable": **the function's body can be expressed using existing primitives + ECE language features, with no host capability dependency**. Anything that needs to inspect a host type tag, manipulate a cons cell directly, or call a syscall stays primitive.

## What Changes

- **MODIFIED** `src/prelude.scm` — add ECE definitions for ~23 primitives that currently live in `src/primitives.scm` as `:cl` templates. Group: pure list accessors, list constructors, structural predicates, and a few trivial standalone functions.
- **MODIFIED** `src/primitives.scm` — remove the `define-host-primitive` declarations for the migrated primitives. Their primitive IDs are removed from `primitives.def` (or marked unused) and the corresponding `ece-NAME` functions disappear from the regenerated `bootstrap/primitives-auto.lisp`.
- **MODIFIED** `bootstrap/primitives-auto.lisp` — regenerated; ~23 fewer `defun` forms.
- **MODIFIED** `bootstrap/bootstrap.ecec` — regenerated to pick up the new prelude definitions and the removed primitive references.
- **MODIFIED** `bootstrap/<space>-zone.lisp` files — regenerated; call sites that previously dispatched to the moved primitives now compile to direct calls into the prelude space.
- **NO BREAKING CHANGES** — all moved primitives keep the same public name, parameter list, and observable behavior. Only the implementation location changes.

### Migration tiers (in execution order)

1. **Tier 1 — pure list accessors** (9 primitives): `compiled-procedure-entry`, `compiled-procedure-env`, `continuation-stack`, `continuation-conts`, `continuation-winds`, `%primitive-id-of`, `%global-env-frame`, `port-line`, `port-col`
2. **Tier 2 — pure list constructors** (4 primitives): `%make-compiled-procedure`, `%make-continuation`, `%make-primitive`, `make-parameter`
3. **Tier 3 — structural and tagged-list predicates** (11 primitives): `input-port?`, `output-port?`, `port?`, `parameter?`, `keyword?`, `null?`, `compiled-procedure?`, `continuation?`, `primitive?`, `procedure?`, `%env-frame?`
4. **Tier 4 — trivial standalone** (2 primitives): `list`, `clear-screen`

### What stays primitive (and why)

Every primitive not listed above stays where it is. They fall into clear categories:

- **Cons-cell atoms**: `car`, `cdr`, `cons`, `set-car!`, `set-cdr!` — the irreducible cons-cell operations. ECE itself is built on these.
- **Vector atoms**: `make-vector`, `vector`, `vector-ref`, `vector-set!`, `vector-length` — same role for vectors.
- **Host type predicates**: `pair?`, `number?`, `string?`, `symbol?`, `integer?`, `char?`, `vector?`, `hash-table?` — they ask the host runtime "what type is this object?", and there's no ECE-side way to answer that question without one type primitive per host type.
- **Numeric and comparison ops**: `+`, `-`, `*`, `/`, `=`, `<`, `>`, `eq?` — host arithmetic and identity comparison.
- **String ops**: `string-length`, `string-ref`, `string-append`, `substring`, `string`, `string->symbol`, `symbol->string` — host string operations.
- **Character ops**: `char->integer`, `integer->char`.
- **Bitwise ops**: `bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`.
- **Math**: `sin`, `cos`, `sqrt`, `truncate`, `floor`, `exact->inexact`.
- **All I/O**: `read-char`, `peek-char`, `read-line`, `read-byte`, `write-byte`, `display`/`write` primitives, `open-input-file`, `open-output-file`, port operations, etc.
- **All hash table operations**: native CL hash tables.
- **Compiler/runtime hooks**: `apply-compiled-procedure`, `execute-from-pc`, `extend-environment`, `get-macro`, `set-macro!`, `try-eval`, `make-parameter` (already moved), `%raw-error`.
- **Syscalls and process**: `exit`, `command-line`, `get-environment-variable`, `current-milliseconds`, `wall-clock-ms`, `sleep`, `%file-exists?`, `%list-directory`, `%make-directory`, `%chmod`.
- **Instruction-vector and space registry**: all `%intern-ece`, `%instruction-vector-*`, `%label-table-*`, `%space-*`, `%create-space`, `%current-space-id`, etc.
- **Boot stubs**: `%register-primitive!`, `%init-asm-syms`, `%create-repl-space!`, etc. — these are no-ops on CL but real primitives on WASM.
- **Tracing and serialization**: `trace`, `untrace`, `write-to-string`, `write-to-string-flat`.

## Capabilities

### New Capabilities
None — this is purely a relocation of implementation, not a change in observable behavior.

### Modified Capabilities
None — every migrated primitive keeps its public name, parameter list, and observable behavior. The change is internal: their definition site moves from `src/primitives.scm` (CL template) to `src/prelude.scm` (ECE source). No existing spec documents these primitives at the requirements level.

## Impact

- **Affected code**: `src/primitives.scm` (removals), `src/prelude.scm` (additions), `primitives.def` (ID list), `bootstrap/primitives-auto.lisp` (regenerated), `bootstrap/bootstrap.ecec` (regenerated), all `bootstrap/*-zone.lisp` files (regenerated since call sites change).
- **CL kernel size**: shrinks by ~26 `defun` forms (~120-150 lines of CL).
- **Performance**: negligible — moved primitives now go through the regular ECE function-call path (a goto into the prelude space), but the prelude space runs as a compiled zone so the cost is one CL function call rather than an interpreter dispatch.
- **WASM port**: each migrated primitive is one less function to implement in WAT for Phase 2.
- **Two-pass bootstrap required** — per the documented pitfall in MEMORY.md, primitive removal needs (1) add ECE def + bootstrap, (2) remove host primitive + bootstrap again. Each tier is its own commit and each commit must be a clean two-pass cycle.
- **Rollback**: per-tier reverts are clean — re-add the `define-host-primitive` form, re-bootstrap. No data migration involved.
