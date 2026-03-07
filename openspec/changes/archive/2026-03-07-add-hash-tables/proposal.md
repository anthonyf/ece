## Why

IF game state quickly outgrows individual variables and alists. Hash tables provide a natural key-value store for inventory, flags, NPC attributes, and other structured game data. By using a tagged s-expression representation, hash tables are serializable by default — critical for save/load via `call/cc` continuations.

## What Changes

- **Curly brace literal syntax**: `{name "Alice" age 30}` reads as a self-evaluating hash table. Keys are not evaluated (like `quote`). Uses `read-delimited-list` on the ECE readtable.
- **`hash-table` constructor function**: `(hash-table 'name "Alice" 'age 30)` — keys are evaluated, enabling computed keys.
- **Hash table operations**: `hash-table?`, `hash-ref`, `hash-set!` (mutating), `hash-set` (functional), `hash-remove!`, `hash-has-key?`, `hash-keys`, `hash-count`.
- **Self-evaluating**: Hash table literals `(hash-table ...)` are recognized by `self-evaluating-p`, enabling write/read round-tripping.
- **Key equality**: Uses `equal?` to support symbols, strings, numbers, and chars as keys.

## Capabilities

### New Capabilities
- `hash-table-literals`: Curly brace reader syntax and self-evaluating tagged list representation.
- `hash-table-ops`: Constructor function, predicate, accessors, mutators, and queries.

### Modified Capabilities

## Impact

- `src/main.lisp` — New reader macro on `*ece-readtable*` for `{}`; new wrapper functions for hash operations; `self-evaluating-p` gains a hash-table check; new exports.
- `tests/main.lisp` — New test suite for hash table operations and literal syntax.
