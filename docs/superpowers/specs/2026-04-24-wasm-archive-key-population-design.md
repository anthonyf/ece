# WASM Archive-Key Population

**Date:** 2026-04-24
**Status:** Designed, ready for implementation plan
**Scope:** small — one WAT file + one roadmap edit
**Closes:** "Known follow-up" #3 in `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md`

## Context

PR #167 shipped P2's hybrid continuation-serialization strategy: archive-registered code-objects serialize as `(%ser/co-ref <stem> <index>)`; anonymous ones serialize inline via `(%ser/co-inline …)`. The dispatch reads each code-object's `archive-key` slot (non-null → by-ref; null → inline) and deserialization looks up by-ref entries through primitive 260 (`%archive-co-lookup`).

On CL this works end-to-end: `register-archive-code-objects` in `src/runtime.lisp:2088` stamps `archive-key` on each loaded code-object AND inserts into the `*archive-code-objects*` registry.

On WASM, PR #167 left both halves stubbed: the archive loader doesn't populate `archive-key` (cos always have `archive-key = null` → always inline), and primitive 260 is a no-op stub returning `#f`. Consequence:

- CL-produced continuations containing `(%ser/co-ref …)` fail to deserialize on WASM with `ece-deser-missing-archive-error`.
- WASM serialization always inlines, inflating continuation-blob sizes.

This spec closes the gap.

## Goals

1. WASM `$load-archive-impl` stamps `archive-key = (cons <stem-sym> <index-fixnum>)` on each loaded code-object, matching CL's semantics.
2. WASM maintains an archive registry so primitive 260 (`%archive-co-lookup`) can resolve `(stem, index)` → code-object.
3. Cross-host continuation round-trips: a CL-produced blob with `(%ser/co-ref <stem> <index>)` deserializes cleanly on WASM when the same archive is loaded.

## Non-goals

- No serialization-format changes. The `(%ser/co-ref …)` shape is fixed.
- No CL-side changes. CL already does this correctly.
- No explicit unload API. Per the Scheme ecosystem survey (Chez, Racket, Guile, Gambit, Chicken, MIT, SBCL), none offer explicit unload for compiled files; re-load overwrites bindings, distinct loads accumulate — the standard answer is "restart the image." This design matches.
- No LRU eviction or size cap on the registry. Eviction would silently break continuations referencing evicted archives — correctness regression.
- No new WASM type declarations. Registry uses existing `$hash-table` and `$pair` primitives.

## Design

### 1. Archive registry

One new module-level global, lazy-initialized:

```wat
;; Archive registry: outer $hash-table keyed by file-stem symbol ref
;; (ref.eq on interned symbols) mapping to inner $hash-tables keyed
;; by index-fixnum (ref.eq on i31refs) mapping to $code-object refs.
;; Null until first registration — $archive-registry-put lazy-creates
;; the outer hash on first call.
(global $archive-registry (mut (ref null eq)) (ref.null eq))
```

Using the existing `$hash-table` primitive for both levels — no new type declarations. `ref.eq` semantics for both symbol and fixnum keys (WASM interns these so identity works across allocations).

### 2. Helpers

**`$archive-file-stem-symbol(archive) → (ref null eq)`** — mirrors CL's `archive-file-stem-symbol`:

- Extract `:file` via `$archive-plist-get-by-id` with `$sym-id-file`.
- If missing or not a string, return `ref.null eq` (caller skips registration, matching CL's graceful degradation).
- Scan the string for the last `#\.` (character code 46); if present, take the prefix; otherwise use the whole string.
- Intern the prefix as a symbol via the existing `$intern` helper. Return the symbol ref.

CL semantics to match: strips *any* trailing dotted extension (not specifically `.scm`), so `"foo.bar.baz"` → stem `foo.bar`.

**`$archive-registry-put(stem, index, co)`:**

- If `$archive-registry` is null, allocate an outer `$hash-table` with initial capacity 32.
- Look up `stem` in outer. If missing, allocate an inner `$hash-table` (initial capacity 32) and insert into outer via `$hash-set-impl`.
- Insert `(index → co)` into the inner hash via `$hash-set-impl` (overwrites on matching key per existing semantics).

Re-load of an archive: inserts with the same stem → outer-hash overwrites the inner-hash-reference → new inner hash has all the new archive's cos. Old inner hash becomes unreachable (GC-managed). Code-objects from the previous load remain reachable only through external references (existing closures, captured continuations). Matches CL exactly.

**`$archive-registry-get(stem, index) → (ref null eq)`:**

- If `$archive-registry` is null, return `$false` (global singleton).
- Outer lookup; if miss, return `$false`.
- Inner lookup; if miss, return `$false`.
- Otherwise return the code-object ref.

### 3. `$load-archive-impl` integration

Just before the entry loop in Pass 1:

```wat
(local.set $stem (call $archive-file-stem-symbol (local.get $archive)))
```

Inside Pass 1 per iteration (after the current `struct.set $code-object …` metadata stamps):

```wat
;; Stamp archive-key = (cons stem (fixnum index)). Skip when stem
;; is null — matches CL's skip-registration behavior.
(if (i32.eqz (ref.is_null (local.get $stem)))
  (then
    (struct.set $code-object $archive-key (local.get $co)
      (call $cons
        (local.get $stem)
        (call $make-fixnum (local.get $i))))
    (call $archive-registry-put
      (local.get $stem)
      (call $make-fixnum (local.get $i))
      (local.get $co))))
```

Adds one `$stem` local to `$load-archive-impl`.

### 4. Primitive 260 (`%archive-co-lookup`) — rewrite

Current stub:

```wat
(if (i32.eq (local.get $id) (i32.const 260))
  (then (return (global.get $false))))
```

Replaced with:

```wat
(if (i32.eq (local.get $id) (i32.const 260))
  (then (return (call $archive-registry-get
    (call $arg1 (local.get $args))
    (call $arg2 (local.get $args))))))
```

Also delete the stale comment block at primitive 260 that says "The WASM archive loader doesn't populate a (stem . index) registry (archive-key stamping is a CL-only follow-up) …". Replace with a brief note on the new semantics.

### 5. New sym-id global (if not present)

Check whether `$sym-id-file` already exists (looked up elsewhere). If not, add it to the existing sym-id-initialization block in `$init-ascii-chars`, mirroring `$sym-id-version` / `$sym-id-entries` / etc. Initial value interned from the 4-byte string `"file"`.

## Testing

Integration-level only. No new automated test harness.

- **Bootstrap is the integration test.** If the stamp-and-register logic corrupts code-objects or the registry fails, `make test-wasm` bootstrap will fail.
- **Manual smoke after implementation:**
  1. `scripts/ece-gh` not involved — purely CL+WASM build+test loop.
  2. From a WASM REPL (or via a temporary test call in `wasm/test.js`): pick any code-object from `bootstrap.ecec` (e.g., `car` in prelude). Invoke `code-object-archive-key` on it; expect `(prelude . <index>)` instead of `#f`.
  3. Serialize a continuation that closes over an archive-registered code-object. Parse the resulting string and confirm it contains `(%ser/co-ref prelude <index>)` rather than `(%ser/co-inline …)`.
  4. Call `%archive-co-lookup` with a known stem + index; expect a code-object. Call with an unknown stem; expect `#f`.

## Edge cases

- **Archive with missing `:file`:** `$archive-file-stem-symbol` returns null; Pass 1 skips stamping + registration. Cos have `archive-key = null`, serialize inline. Matches CL.
- **Archive with non-string `:file`:** same path; returns null; skip.
- **Archive with no `.` in filename:** stem is the full filename; still valid.
- **Re-loading the same archive:** outer hash overwrites the inner-hash reference; new cos fully replace old in the registry. Old cos survive only via external references (expected).
- **`%archive-co-lookup` with unknown stem OR out-of-range index:** returns `$false`; deserializer raises `ece-deser-missing-archive-error`. Matches CL.
- **Empty archive (`:entries ()`):** no Pass 1 iterations; stem extraction still happens (harmless); registry has an outer-hash entry with empty inner hash. Subsequent loads of non-empty archives with the same stem overwrite cleanly.

## Risks

- **String handling for stem extraction.** The most bug-prone WAT section; last-`.`-scan in WAT is verbose. Mitigation: write it to match CL's `position … :from-end t` behavior exactly, with unit-test-level care via manual verification on the bootstrap filename.
- **Inner-hash initial capacity vs. archive size.** `bootstrap.ecec`'s compiler archive has hundreds of code-objects. Initial cap 32 → `$hash-set-impl` will grow (doubling) to 64 → 128 → 256 → 512 on its own. Mitigation: accept the 4-5 regrowths as one-time cost at load.
- **Symbol interning identity.** `$intern` must return the same sym ref for identical strings across calls, so ref.eq works for registry lookups. Already true in the existing codebase — all sym-id globals rely on this.

## References

- CL reference: `src/runtime.lisp:2063` (`archive-file-stem-symbol`), `2088` (`register-archive-code-objects`).
- Current WAT stub: `wasm/runtime.wat` at primitive 260.
- P2 design: `docs/superpowers/specs/2026-04-22-codeobj-serialization-design.md`.
- Roadmap entry: `docs/superpowers/specs/2026-04-20-code-objects-completion-roadmap.md` (Known follow-ups, third bullet).
- Scheme ecosystem survey justifying "no unload API": Chez, Racket, Guile, Gambit, Chicken, MIT, SBCL all accept monotonic module-cache growth over session lifetime.
