## Why

Stage 1 coverage expansion (PR #143) put all bootstrap spaces in compiled zones, eliminating the interpreter overhead that previously made "everything in ECE" too slow. We can now move a small set of trivial primitives from `src/primitives.scm` to `src/prelude.scm` without measurable performance impact, because the ECE definitions get compiled to native CL via the same codegen as the rest of the prelude. Each primitive moved is one less function to port to WAT in Phase 2 (the WASM runtime), shrinking the portability surface area.

The criterion for "movable": **the function's body can be expressed using existing primitives + ECE language features, with no host capability dependency, AND the same ECE implementation must produce correct results on both the CL and WASM runtimes**.

### Scope narrowed during implementation

The original proposal included 4 tiers totaling ~26 primitives. During implementation, tiers 1-3 were discovered to violate the criterion above: the targeted primitives (`compiled-procedure-*`, `continuation-*`, `%primitive-id-of`, `%global-env-frame`, `port-line`, `port-col`, `%make-*`, and the type predicates) have **platform-specific representations**. On CL they're tagged lists, but on WASM they're WasmGC structs — compiled-procs, continuations, primitives, and ports each use `struct.get` field access on WASM (see `wasm/runtime.wat` lines 4852-5043). A portable ECE definition like `(define (compiled-procedure-entry p) (cadr p))` works on CL but fails on WASM with "car: not a pair" because the WASM struct is not a pair. Until the ECE language has a portable way to dispatch on platform-specific representations, these primitives must stay primitive.

Only **tier 4** (`list`, `clear-screen`) is genuinely portable and was implemented. Tiers 1-3 are abandoned.

## What Changes

- **MODIFIED** `src/prelude.scm` — add ECE definitions for `list` and `clear-screen`.
- **MODIFIED** `src/primitives.scm` — remove the `define-host-primitive` declarations for `list` and `clear-screen`.
- **MODIFIED** `primitives.def` — change the `platform` field for IDs 8 (`list`) and 84 (`clear-screen`) from `core` to `ece`. IDs are not renumbered.
- **MODIFIED** `bootstrap/primitives-auto.lisp` — regenerated; 2 fewer `defun` forms (`ece-list`, `ece-clear-screen`).
- **MODIFIED** `bootstrap/bootstrap.ecec` — regenerated to pick up the new prelude definitions.
- **MODIFIED** `bootstrap/<space>-zone.lisp` files — regenerated to reflect the new call sites.
- **NO BREAKING CHANGES** — both migrated functions keep the same public name, parameter list, and observable behavior on CL. On WASM, `list` behaves identically; `clear-screen` now writes ANSI escape sequences (previously a no-op), which is a change for browser contexts but is not exercised by any existing test or sandbox program.

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

- **Affected code**: `src/primitives.scm` (removed `list` and `clear-screen`), `src/prelude.scm` (added ECE definitions), `primitives.def` (IDs 8 and 84 marked `ece`), `bootstrap/primitives-auto.lisp` (regenerated), `bootstrap/bootstrap.ecec` (regenerated), all `bootstrap/*-zone.lisp` files (regenerated).
- **CL kernel size**: shrinks by 2 `defun` forms.
- **Performance**: negligible — moved primitives now go through the regular ECE function-call path (a goto into the prelude space), but the prelude space runs as a compiled zone so the cost is one CL function call rather than an interpreter dispatch.
- **WASM port**: 2 fewer functions to implement in WAT for Phase 2. `list` is a trivial rest-arg identity; `clear-screen` is browser-context garbage (writes escape sequences to console instead of no-op), but no existing test or sandbox program calls it on browser.
- **Two-pass bootstrap required** — per the documented pitfall in MEMORY.md, primitive removal needs (1) add ECE def + bootstrap, (2) remove host primitive + bootstrap again.
- **Rollback**: `git revert` the single commit cleanly restores the primitives.
