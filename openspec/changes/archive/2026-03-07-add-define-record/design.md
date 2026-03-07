## Context

ECE has a hash table system (`(:hash-table (key . val) ...)`) with constructors, accessors, mutators, and literal syntax. Records will be a macro layer on top of this — no CL-side changes needed.

The macro will live in the stdlib section of `src/ece.lisp`, after `map`/`filter`/`apply`/`append` are available (since the macro body uses them at expansion time).

## Goals / Non-Goals

**Goals:**
- Provide `define-record` macro that generates all record operations from a name and field list
- Records are hash tables — fully compatible with `hash-ref`, `hash-set!`, serialization, etc.
- Support both mutable (`set-<name>-<field>!`) and functional (`<name>-with-<field>`) updates
- Provide `copy-<name>` for shallow copying

**Non-Goals:**
- Inheritance or record composition
- Default field values
- Validation or type checking on fields
- Custom printing

## Decisions

### 1. Pure ECE macro, no CL-side changes

The macro uses existing primitives: `hash-table`, `hash-ref`, `hash-set!`, `hash-set`, `hash-table?`, `string->symbol`, `symbol->string`, `string-append`, `map`, `apply`, `append`.

**Alternative**: Add a CL-side `defrecord` handler. Rejected — unnecessary complexity when the macro system is sufficient.

### 2. Symbol keys for fields (not keywords)

Store field names as quoted symbols: `(hash-table 'type 'point 'x 10 'y 20)` producing `(:hash-table (type . point) (x . 10) (y . 20))`.

**Alternative**: Use keyword keys (`:type`, `:x`). Rejected — keywords aren't self-evaluating in ECE (would need a CL-side change to `self-evaluating-p`), and symbols work fine with the existing `hash-ref` which uses `equal`.

### 3. Type discrimination via `'type` key

Each record stores `(type . <record-name>)` in its hash table. The predicate checks `(eq? (hash-ref obj 'type) '<name>)`.

**Alternative**: Use a special tag like `:record-type`. Rejected — simpler to use a plain symbol key, and it's visible/inspectable.

### 4. Functional update via `hash-set` (immutable)

`(<name>-with-<field> obj val)` returns a new hash table via `hash-set` (the existing immutable variant). The original is unchanged.

### 5. Copy via field-by-field reconstruction

`(copy-<name> obj)` creates a new hash table by reading all fields from the original. This is a shallow copy — nested mutable values share identity.

## Risks / Trade-offs

- **No arity checking on constructor**: `(make-point 1)` with missing fields will create a record with `nil` for the missing field. Acceptable for a lightweight record system.
- **No field existence checking on accessors**: `(point-x some-non-point)` returns `nil` silently. Same behavior as raw `hash-ref`.
- **`type` key is user-visible**: Users could accidentally overwrite it with `(hash-set! rec 'type 'other)`. Acceptable — don't protect against intentional misuse.
