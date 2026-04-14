## Context

The WASM runtime packs five kinds of values into i31ref to avoid heap allocation:

```
;; wasm/runtime.wat:180-191
;;   Fixnum:  (n << 1)                        ;; bit 0 = 0
;;   Char:    (codepoint << 4) | 0x0B         ;; low 4 bits = 1011
;;   #f:      ref.i31 1    (0x01)
;;   #t:      ref.i31 3    (0x03)
;;   nil:     ref.i31 5    (0x05)
;;   eof:     ref.i31 7    (0x07)
;;   void:    ref.i31 9    (0x09)
```

`$is-fixnum` checks `ref.test (ref i31) v AND (bit 0 == 0)`. `$is-char` checks `ref.test (ref i31) v AND (low 4 bits == 0x0B)`. Specials are compared via `ref.eq` against global singletons.

The fixnum range is `[-2^29, 2^29-1]`, not the i31's `[-2^30, 2^30-1]`, because the `<< 1` shift consumes one bit. Removing that shift is only possible if no other tagged value is allowed to land on an even i31 — which means **everything else currently in i31 has to leave**.

This proposal moves chars and all five specials out of i31 into heap-allocated structs. ECE primitives already have precedent for this: `$primitive` (line 108) is a struct type, not a tagged i31, and performs just fine.

## Goals / Non-Goals

**Goals:**
- Fixnum encoding becomes the identity: `ref.i31 n` to make, `i31.get_s v` to read, `ref.test (ref i31) v` to test. Range is the full i31 signed range `[-2^30, 2^30-1]`.
- Chars become a single-field struct; ASCII chars (codepoints 0-127) are pre-interned at module init so the hot path is allocation-free.
- Specials become singleton struct instances; `ref.eq` comparison is unchanged.
- No change to .ecec serialization format or to any CL-side code.
- SHA-1, bitwise-large, bitwise-variadic, and all existing test coverage continue to pass byte-for-byte.

**Non-Goals:**
- No i63 or 64-bit fixnum path. If a value exceeds the 31-bit range it still falls back to float-box (same as today, just with a wider fixnum band).
- No user-visible API change. Scheme code sees the same `fixnum?`, `char?`, `eof-object?`, etc., with the same results for inputs that previously fit. Inputs in the newly-fixnum band now type-test as fixnums where they type-tested as "number" (float-box) before — a positive refinement, never a regression.
- No change to how chars are displayed, read, or compared. The reader still produces `#\a` for the character `a`; `char=?` / `char<?` still work on codepoints.
- No parallel code path. The new scheme replaces the old one — we're not carrying both in parallel behind a flag.

## Decisions

### 1. Chars become a single `$char` struct with one i32 field

**Choice:** Add `(type $char (struct (field $codepoint i32)))`. Every char reference is a `(ref $char)`. `$make-char` allocates a new struct (or returns an interned one — see decision 3). `$char-codepoint` reads the field. `$is-char` is `ref.test (ref $char) v`.

**Rationale:** Straightforward and type-safe. Subtyping makes `(ref null eq)` a supertype, so chars still flow through the uniform value pipe.

**Alternative considered:** Packing codepoint into a 21-bit immediate field and stealing another type bit. Rejected — modern GC-wasm toolchains are all designed around struct types for boxed values; reinventing a custom tag scheme provides no measurable benefit and loses type-safety on reads.

### 2. Specials become singleton struct instances, one type each

**Choice:** Define empty struct types `$false-type`, `$true-type`, `$nil-type`, `$eof-type`, `$void-type`. Create one global instance of each at module-init time. `$false`, `$true`, `$nil`, `$eof`, `$void` are globals of type `(ref $<type>-type)`. `ref.eq` between a value and a global is pointer equality — the same comparison semantics as today.

```wat
(type $false-type (struct))
(global $false (ref eq) (struct.new $false-type))
```

**Rationale:** Gives each special a unique type identity, so a future `(false? v)` could use `ref.test` if that's cheaper than `ref.eq`. Most code paths will continue to use `ref.eq` against the global, which is identical in cost to the current `ref.eq` against an i31 literal.

**Alternative considered:** One shared `$special` struct with an i32 `$tag` field and five instances. Rejected — requires reading the field to distinguish them, whereas separate types let `ref.test (ref $false-type)` work. The five empty structs cost 5 pointers of module-init overhead; tolerable.

**Alternative considered:** Keep specials on i31 (as-is), only move chars. Rejected — chars alone don't free up the fixnum range. Bit 0 is still reserved because the specials are odd. No fixnum-range benefit.

### 3. ASCII chars are pre-interned at module init

**Choice:** Allocate a 128-element array of `$char` structs at startup, one per codepoint in `[0, 127]`. `$make-char(cp)` checks `cp < 128` and returns the interned entry; otherwise allocates a fresh struct.

```wat
(global $ascii-chars (ref $char-array) ...)   ;; 128 pre-allocated chars

(func $make-char (param $cp i32) (result (ref eq))
  (if (i32.lt_s (local.get $cp) (i32.const 128))
    (then (return (array.get $char-array
            (global.get $ascii-chars)
            (local.get $cp)))))
  (struct.new $char (local.get $cp)))
```

**Rationale:** ASCII is the overwhelming majority of char allocations in ECE workloads — `read-char`, `string-ref`, every character literal in source code, every iteration over a string. Without interning, these would trade zero-cost tag-unboxing for one heap alloc each. Interning makes the common case a single array load, which is cheaper than the current `ref.i31 ((cp << 4) | 0x0B)` + later `(cp >> 4)` decode.

**Alternative considered:** Intern the full Unicode BMP (65536 entries). Rejected — 512 KB of pre-allocated structs for unclear benefit. Start with 128, widen if measurement shows it matters.

**Alternative considered:** No interning at all; always allocate. Rejected — char allocation is on the hottest path (reader + string iteration), and ASCII is hit >99% of the time. The measurement cost of "is this slow?" is much higher than just interning 128 chars upfront.

### 4. `$make-fixnum-or-float` range widens to the new fixnum range

**Choice:** The range check in `$make-fixnum-or-float` and `$f64-to-ece-number` changes from `[-2^29, 2^29-1]` (`-536870912..536870911`) to `[-2^30, 2^30-1]` (`-1073741824..1073741823`). Values in the new band that previously took the float-box path now stay as fixnums.

**Rationale:** Obvious consequence of the widened fixnum encoding. Without this update, `$make-fixnum-or-float` would needlessly overflow into float-box at the old 29-bit boundary despite the new 30-bit capacity.

### 5. Audit, don't abstract, direct i31 usages

**Choice:** Grep `runtime.wat` for every `i31.get_s` / `i31.get_u` / `ref.i31 (i32.shl ... 1)` / `i32.shr_s ... 1` site, and fix each one that embedded the shift convention. Do not introduce an abstraction layer.

**Rationale:** The fixnum encoding is low enough in the runtime that an abstraction wrapper would just be `$make-fixnum`/`$fixnum-value` with an extra layer of indirection. The direct audit is ~30 minutes of grep + edit; an abstraction refactor is a week of ripple effects. Sites that already call `$make-fixnum`/`$fixnum-value` are automatically correct.

Expected sites to audit:
- `$f64-to-ece-number` — range check updated
- `$make-fixnum-or-float` — range check updated
- `$is-fixnum` — simplifies
- `$fixnum-value` — simplifies
- `$make-fixnum` — simplifies
- Any spot that did `(i32.shl n 1)` or `(i32.shr_s v 1)` on an i31 value as a manual encode/decode

### 6. Bootstrap regeneration is required

**Choice:** After the runtime change lands, `make bootstrap` regenerates the `.ecec` files. The serialization format is unchanged (fixnums serialize as decimal integers, chars as codepoints), but the bootstrap runs the *new* runtime at compile time, so the fresh files' compiled code makes use of the widened fixnum range where possible.

**Rationale:** A stale `.ecec` file compiled under the old runtime would embed assumptions about the fixnum boundary — for example, a literal `1073741823` in source code might have been compiled to a float-box under the old runtime. After the runtime update, that literal should be a fixnum. Regenerating guarantees consistency and catches any compile-time mismatch.

**Validation gate:** `make bootstrap` must run clean twice in a row (self-hosting stability) before declaring the bootstrap fresh.

## Risks / Trade-offs

- **Every char allocation outside ASCII is now a heap alloc.** In practice, most ECE workloads are ASCII-dominated (source code is ASCII, REPL input is ASCII, test strings are ASCII). For a workload that genuinely processes non-ASCII text at scale, we'd want to extend the intern table or add a bounded LRU cache. Not needed today.
- **Module-init cost.** Five struct singletons + 128 ASCII chars = 133 heap allocs at startup. Measured against the ~thousands of other module-init operations, this is noise.
- **`ref.eq` against a global vs. `ref.eq` against an i31 literal.** Both compile to pointer equality in every known wasm engine. No expected cost difference.
- **Two-pass bootstrap.** A naive single-pass bootstrap *may* hit the trap documented in the "Two-pass bootstrap for primitive migration" memory. Mitigation: run `make bootstrap` twice and diff the outputs. If the second pass differs from the first, there's a fixed-point issue to track down.
- **`.ecec` format compatibility.** Unchanged. Old .ecec files load on the new runtime without modification; new .ecec files load on the old runtime without modification. Only the in-memory representation changes.

## Migration Plan

1. Land runtime changes in `wasm/runtime.wat` (struct types, helpers, ASCII table).
2. Run `make test-wasm` — catches the primary correctness cases. If this passes, the structural change is sound.
3. Run `make bootstrap` twice; diff the second pass against the first. If different, investigate before continuing.
4. Run the full `make test` suite. Regressions must be zero.
5. Add `tests/ece/common/test-fixnum-full-range.scm` with values in the widened band.
6. Archive the change in-PR per the archive-before-merge rule.

Rollback plan: single-commit revert. The runtime change is self-contained and doesn't touch the CL side, bootstrap format, or user-facing API.

## Open Questions

- **Should `most-positive-fixnum` / `most-negative-fixnum` (if exposed) update their values?** Yes — they're the canonical way for Scheme code to query the runtime's range, and they should reflect the new 30-bit boundary. Audit via grep; update if present.
- **Should we take this opportunity to move other currently-special values off i31?** No. The five specials are the only i31 tenants besides fixnums and chars. Primitives are already structs. Nothing else to consolidate.
- **Should we add a `char-intern-size` diagnostic primitive to surface the intern table size?** Not in this PR — diagnostics are out of scope. A future introspection/profiling PR can add it if warranted.
