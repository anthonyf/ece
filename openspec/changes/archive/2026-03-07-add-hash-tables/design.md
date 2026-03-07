## Context

ECE currently supports alists for key-value data, but they lack dedicated syntax and operations. Game state (inventory, flags, NPC data) is managed via individual `define`/`set` variables. Hash tables provide a more natural grouping. The design must preserve serializability — continuations captured by `call/cc` must round-trip through write/read without special handling.

## Goals / Non-Goals

**Goals:**
- Tagged s-expression representation that serializes naturally
- Curly brace literal syntax `{k v ...}` on the ECE readtable
- Constructor function for programmatic creation with computed keys
- Both mutable (`hash-set!`) and functional (`hash-set`) update operations
- `equal?`-based key lookup supporting symbols, strings, numbers, chars
- Self-evaluating so hash table values pass through the evaluator unchanged

**Non-Goals:**
- CL native hash tables (not serializable without custom code)
- Performance optimization for large tables (game state is small)
- Nested literal syntax (e.g., `{a {b 1}}` — inner `{}` would work naturally since the reader is recursive)

## Decisions

### 1. Tagged alist representation

Internal form: `(hash-table (k1 . v1) (k2 . v2) ...)`

This is a cons cell with `hash-table` in the car and an alist in the cdr. Mutation works by modifying the cdr — the identity of the outer cons cell is preserved, so variables pointing to the hash table remain valid after `hash-set!`.

```
      ┌──────────────┐     ┌──────────────┐
  ht ─▶│ hash-table │ ─────▶│ (k1 . v1)    │ ──▶ ...
      └──────────────┘     └──────────────┘
      identity preserved    mutate here
```

**Alternative considered**: CL struct or CL hash table. Rejected because neither serializes as s-expressions through the standard reader.

### 2. Curly brace reader macro

Add `{` and `}` as macro characters on `*ece-readtable*`:

- `{` reads items via `read-delimited-list` until `}`, pairs them as `(k . v)`, wraps in `(hash-table ...)`.
- `}` is set as a terminating macro character (same handler as `)`) so `read-delimited-list` recognizes it.

The reader produces the tagged list directly — no evaluation needed. `{name "Alice"}` → `(hash-table (NAME . "Alice"))`.

### 3. Self-evaluating check

Add to `self-evaluating-p`:

```lisp
(and (consp expr) (eq (car expr) 'hash-table))
```

This must be checked BEFORE `application-p` in the dispatch, which it will be since `self-evaluating-p` is checked first in `:ev-dispatch`.

### 4. Constructor function

`hash-table` is registered as an ECE primitive function (in `*wrapper-primitives*`). It takes alternating key-value arguments and builds the tagged list:

```lisp
(defun ece-hash-table (&rest args)
  (cons 'hash-table
        (loop for (k v) on args by #'cddr
              collect (cons k v))))
```

Since it's a function, arguments are evaluated — keys need quoting for literal symbols: `(hash-table 'name "Alice")`.

### 5. Key equality

All lookups use CL's `equal` (which is ECE's `equal?`). This handles symbols (`eq`), strings (`string=`), numbers (`eql`), and chars (`eql`) uniformly.

### 6. Mutation strategy

`hash-set!` finds an existing key's pair and `setf`s its cdr, or pushes a new pair onto the cdr of the outer cons. The outer cons identity is preserved.

`hash-set` conses a new list — copies the alist with the key updated or added. Does not modify the original.

`hash-remove!` destructively removes a pair from the alist. If the first entry matches, it shifts the second entry into the first position to preserve identity.

## Risks / Trade-offs

- **O(n) lookup**: Acceptable for game state (tens of entries). If someone builds a 10,000-entry hash table, it'll be slow. This is a known trade-off for serializability.
- **Symbol identity in reader**: `{name "Alice"}` reads `name` as `ECE:NAME` (or `CL:NAME` if it's a CL symbol). This matches how symbols work everywhere else in ECE — no surprise.
- **`hash-table` symbol collision**: The symbol `hash-table` is used both as a tag and as a function name. This is fine — `self-evaluating-p` catches the tagged list before the evaluator tries to call it as a function.
