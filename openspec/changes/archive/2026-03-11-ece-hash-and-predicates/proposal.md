## Why

The CL kernel currently implements ~75 primitives that could be written in ECE itself, adding porting surface area for a future WASM target. Hash table operations (10 primitives, ~60 lines of CL) are the clearest win — ECE hash tables are already alist-based structures `(:hash-table (k . v) ...)`, so the CL wrappers just do what ECE could do directly. Derived predicates (`not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, `>=`, `equal?`) and math helpers (`abs`, `min`, `max`) are trivial compositions of existing bedrock primitives. Moving these to ECE shrinks the CL kernel by ~25 primitives and ~90 lines.

## What Changes

- Reimplement all 10 hash table operations in ECE (prelude.scm): `hash-table`, `hash-table?`, `hash-ref`, `hash-set!`, `hash-set`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-remove!`
- Reimplement 9 derived predicates in ECE: `not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, `>=`, `equal?`
- Reimplement 3 math helpers in ECE: `abs`, `min`, `max`
- Reimplement list convenience accessors in ECE: `cadr`, `caddr`, `caar`, `cddr`, `list-ref`, `list-tail`, `assoc`, `member`, `append`, `length`, `reverse`
- Remove corresponding CL primitive definitions and wrapper registrations from runtime.lisp
- Remove from `*primitive-procedures*` and `*wrapper-primitives*` alists

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `hash-table-ops`: Hash table operations move from CL primitives to ECE definitions in prelude
- `predicates-and-equality`: `not`, `equal?`, and numeric predicates move from CL to ECE
- `prelude-functions`: New ECE definitions for list accessors, math helpers, and derived predicates
- `prelude-loading`: Prelude must define hash/predicate functions before they're used by other prelude code

## Impact

- `src/runtime.lisp`: Remove ~25 entries from `*primitive-procedures*` and `*wrapper-primitives*`, delete corresponding CL wrapper functions (~90 lines)
- `src/prelude.scm`: Add ~60 lines of new ECE definitions
- `bootstrap/ece.image`: Must regenerate
- Performance: Moved primitives will be slightly slower on CL host (register machine vs native), but identical on a future WASM host
- Boot order: Hash table and predicate definitions must appear early in prelude since other prelude code (e.g., `define-record`) uses them
