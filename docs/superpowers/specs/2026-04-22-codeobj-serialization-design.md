# Code-Object Serialization in Captured Continuations

**Date:** 2026-04-22
**Status:** Designed, ready for implementation plan
**Roadmap entry:** P2 in `2026-04-20-code-objects-completion-roadmap.md`
**Prerequisite:** P0 (WASM archive loader) merged

## Context

`src/prelude.scm:1202` currently emits `(%ser/opaque-co)` as a placeholder for code-object operands in captured continuations. Deserialization rebuilds a closure pointing at an `opaque-co` "space" that does not exist — users calling `save-continuation!` on a CL-side continuation today silently get an un-invokable closure back. Three tests in `test-serialization.scm` are disabled under a `TODO(per-procedure-code-objects §G1)` marker tracking this.

Call/cc serialization is a shipped feature. The placeholder is a known-broken escape hatch, not a design. This spec closes that hole.

## Goals

1. Captured continuations serialize losslessly for the common case (code-objects registered in a loaded archive).
2. Anonymous / REPL-compiled code-objects still serialize — they travel inline with their instructions.
3. Deserialized continuations are `invokable — the three disabled tests in `test-serialization.scm` re-enable and pass.
4. The diagnostic when a by-reference lookup fails is clear and actionable.
5. WASM and CL runtimes produce identical output for the same inputs (round-trippable across hosts if ever needed).

## Non-goals

- **Binary serialization.** Continuations remain s-expression text via `write-to-string-flat`. Compact binary format is a future optimization.
- **Cross-version migration.** Continuations serialized by version N are not guaranteed to deserialize on version N+K. Tooling for schema migration is out of scope.
- **Identity preservation (`eq?`).** A deserialized code-object is a fresh struct; it is not `eq?` to its archive-registered twin. We document this; consumers use `equal?` or name-based comparison.
- **Native-fn preservation.** Deserialized code-objects do not restore compiled-zone `native-fn` bindings. Re-execution falls back to the interpreter path. (The native-fn re-attach happens naturally if the archive is re-loaded in the fresh process.)

## Design

### 1. Two serialization forms

**By-reference form** — used when the code-object is registered via `*archive-code-objects*`:

```
(%ser/co-ref <archive-stem> <index>)
```

- `<archive-stem>` — the symbol used as the first half of the `*archive-code-objects*` key (e.g., `|prelude|`, `|compiler|`).
- `<index>` — the fixnum archive index.

Deserialization looks up `(cons <archive-stem> <index>)` in `*archive-code-objects*` and returns the registered code-object directly.

**Inline form** — used when the code-object is anonymous (compiled at REPL, or otherwise not archive-registered):

```
(%ser/co-inline
  name     <symbol-or-#f>
  arity    <integer-or-#f>
  source-loc <#f>
  labels   ((<sym> . <pc>) ...)
  instructions (<instr-sexp> ...))
```

The field layout mirrors the archive entry format (without the outer `code-object` head). Instructions may recursively contain nested `(%ser/co-ref ...)` or `(%ser/co-inline ...)` forms — code-objects reference other code-objects via `(const (%ser/co-ref ...))` and `(const (%ser/co-inline ...))` operands. The patcher handles arbitrary depth.

(**Note:** this spec uses plain symbols for the inline form's field keys to match the pre-P0.5 archive format. When P0.5 lands, flip these to keywords in the same commit that flips the archive format.)

### 2. Identifying archive-registered code-objects

Serialization needs an O(1) test: given a code-object, is it registered, and if so under what key?

Add a field to the `code-object` struct:

```
(defstruct code-object
  ...
  (archive-key nil))  ; (cons archive-stem index) when registered; nil otherwise
```

Populate in `register-archive-code-objects` in `src/runtime.lisp` (and the ECE mirror in `src/compilation-unit.scm`, and the WAT `$code-object` struct in `wasm/runtime.wat`).

Serialization dispatch becomes:

```scheme
(define (ser/code-object co)
  (let ((key (code-object-archive-key co)))
    (if key
        `(%ser/co-ref ,(car key) ,(cdr key))
        `(%ser/co-inline
           name ,(code-object-name co)
           arity ,(code-object-arity co)
           source-loc ,(code-object-source-loc co)
           labels ,(code-object-labels->alist co)
           instructions ,(map ser/walk-instruction (code-object-instructions co))))))
```

### 3. Deserialization

Extend `%ser/read` (the reader dispatch in `src/prelude.scm`) to recognize the two tags.

**`%ser/co-ref` handler:**

```scheme
((eq? tag '%ser/co-ref)
 (let* ((stem (cadr form))
        (idx  (caddr form))
        (key  (cons stem idx))
        (co   (hash-table-ref/default *archive-code-objects* key #f)))
   (if co
       co
       (error
        (format "Can't deserialize continuation: code-object not loaded (~A index ~A). Ensure the source archive is loaded in this process." stem idx)))))
```

**`%ser/co-inline` handler:**

```scheme
((eq? tag '%ser/co-inline)
 (let* ((fields (cdr form))
        (name (plist-get fields 'name))
        (arity (plist-get fields 'arity))
        (source-loc (plist-get fields 'source-loc))
        (labels-alist (plist-get fields 'labels))
        (instr-sexps (plist-get fields 'instructions))
        (co (make-code-object
             :name name
             :arity arity
             :source-loc source-loc
             :labels (alist->labels-ht labels-alist)
             :source-instructions (list->vector
                                    (map ser/walk-instruction-deser instr-sexps))
             :archive-key #f)))  ; inline means anonymous
   ;; Second pass: resolve operations, patch any nested co-refs in operands.
   (attach-resolved-instructions! co)
   co))
```

`ser/walk-instruction` on the write side recursively rewrites any code-object operand as `(%ser/co-ref ...)` or `(%ser/co-inline ...)`. On read side, `ser/walk-instruction-deser` is the inverse.

### 4. Error UX

When `%ser/co-ref` fails lookup: signal a specific error class `ece-deser-missing-archive-error` with fields `archive-stem` and `archive-index`, plus a clear English message. Don't generic-error; callers (e.g., IF-lib `restore-game`) can catch this specific class and prompt the user to load the corresponding `.ecec` file.

### 5. Round-trip tests

Re-enable the three disabled tests in `tests/ece/cl-only/test-serialization.scm`:
- `continuation serialization round-trips compiled procedure`
- `continuation serialization is compact`
- Third test (find in file — search TODO(per-procedure-code-objects §G1))

Add new tests:
- `%ser/co-ref round-trip via loaded archive` — compile a file, load, capture continuation, save, restore, invoke.
- `%ser/co-inline round-trip via REPL-compiled lambda` — compile at REPL (no archive), capture, save, restore, invoke.
- `%ser/co-ref fails gracefully when archive absent` — pretend the archive is unloaded, expect `ece-deser-missing-archive-error` with stem+index fields.
- `nested code-objects in inline form` — a REPL `(lambda (x) (lambda (y) ...))` captured in a continuation produces a correctly-deserialized outer+inner chain.

### 6. Host parity

Both CL and WASM runtimes must produce identical serialization output for the same input (byte-for-byte when using `write-to-string-flat`). Both must deserialize the other's output.

- CL side: `src/prelude.scm` (serializer lives in ECE and runs on both hosts; so this is shared).
- CL-only helper: `src/runtime.lisp` for the `archive-key` field on the `code-object` defstruct.
- WASM side: `wasm/runtime.wat` `$code-object` struct gains an `$archive-key` field (optional `(ref null eq)` — a pair or null).
- Both hosts populate the field in their archive-load paths (`register-archive-code-objects` on CL; equivalent in the WAT archive loader).

## Implementation Order

Six-commit sequence (each commit green on `make test`):

1. **Add `archive-key` field to `code-object` struct (CL + WASM).** Populate in archive-load paths. Expose via accessor. No serialization changes yet. Tests: a brand-new code-object has `archive-key = #f`; a code-object from `bootstrap.ecec` has the right key.

2. **Add `ser/walk-instruction` (serializer helper).** Recursive walker that rewrites code-object operands. No deserialization yet. Tests: `ser/walk-instruction` on a sample instruction list with a code-object operand produces the expected `(%ser/co-ref ...)` or `(%ser/co-inline ...)` form.

3. **Update `ser/code-object` dispatch in `src/prelude.scm`.** Replace the `%ser/opaque-co` placeholder with the real dispatch. Still no deserialization path. Tests: an explicit serialize-but-don't-deserialize path produces the expected sexp for both cases.

4. **Add `%ser/co-ref` and `%ser/co-inline` readers in `src/prelude.scm`.** Extend the existing `%ser/read` dispatch. Tests: round-trip a continuation; re-enable the three disabled `test-serialization.scm` tests.

5. **Add `ece-deser-missing-archive-error` class and error-UX test.** Ensures the fail-soft path is exercised.

6. **Remove `%ser/opaque-co` placeholder code.** Dead after commits 1-5. Delete the dispatch branch and the emission site. Update `TODO(per-procedure-code-objects §G1)` comments in tests — now delete them as the tests are live.

## Risks

- **`archive-key` field interactions with existing code-object consumers.** Every place that constructs a code-object (compiler, archive loader, REPL compile-and-go) needs to pass `archive-key` explicitly or rely on the defstruct default. Missed spots produce silent `archive-key = #f` which then serializes as inline (not a crash, just a fatter payload). Mitigation: grep `make-code-object` after the change; audit each call site.

- **Recursive cycle in `ser/walk-instruction`.** If a code-object ultimately references itself via some operand chain, the walker hangs. Mitigation: use a visited-set keyed on code-object identity during the walk. Low likelihood (compiler doesn't produce cyclic references currently) but worth a guard.

- **WAT `$archive-key` field default.** When a code-object is constructed via the primitive `%make-code-object` (id 250), the new field needs a null default. If the WAT `struct.new $code-object` expression forgets the new field, compile fails — detectable at WAT compile time, so low risk.

- **`.ecec` file format bloat.** An inline code-object in a continuation blob embeds its full instruction vector. A REPL session with a long-lived continuation capturing a big `let-over-lambda` serializes as kilobytes per code-object. Mitigation: document in the roadmap that inline-dominated continuations are a known cost of the hybrid model.

## References

- `src/prelude.scm:1202` — current `(%ser/opaque-co)` emission site.
- `src/prelude.scm:1301-1306` — current `%ser/read` dispatch.
- `src/runtime.lisp` — `*archive-code-objects*` registry, `register-archive-code-objects`.
- `tests/ece/cl-only/test-serialization.scm` — disabled tests under `TODO(per-procedure-code-objects §G1)`.
- `wasm/runtime.wat` — `$code-object` struct definition, archive loader.
- Roadmap: `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md` (P2 entry).
