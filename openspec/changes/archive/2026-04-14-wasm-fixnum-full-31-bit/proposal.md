## Why

The WASM runtime's fixnum range is `[-2^29, 2^29-1]` — two bits less than the i31ref's theoretical signed capacity of `[-2^30, 2^30-1]`. One bit is lost because bit 0 of i31 is used as a tag: **fixnums** store their value as `n << 1` (bit 0 = 0), while **characters** and the five **special singletons** (`#f`, `#t`, `nil`, `eof`, `void`) use odd i31 values to distinguish themselves from fixnums.

```
;; Current encoding (wasm/runtime.wat lines 184-191):
;;   Fixnum:  n << 1                       (bit 0 = 0)
;;   Char:    (codepoint << 4) | 0x0B      (low 4 bits = 1011)
;;   #f:      0x01   #t: 0x03   nil: 0x05
;;   eof:     0x07   void: 0x09
```

The surprising 29-bit limit is already documented as a known pitfall in `project_wasm_fixnum_range.md`. The cost is twofold:

1. **Performance** — values in the bands `[2^29, 2^30-1]` and `[-2^30, -2^29-1]` unnecessarily take the slow float-box path, even though they fit in an i31 signed integer. Bit patterns for useful constants (array indices into multi-million-element vectors, 30-bit bitmasks, timestamps in half-hour-of-day resolution, etc.) hit this cliff.
2. **Bug magnet** — "fixnum" in a Scheme implementation typically means "machine-word integer". The 29-bit limit violates that expectation and has already caused one near-miss during the PR #150 investigation.

The structural fix is to evict chars and specials from i31 so that i31ref is used exclusively for fixnums. No tag bit is needed and the full 31-bit signed range becomes available.

## What Changes

- **ADDED** new struct type `$char` with an `i32 $codepoint` field and an `i32 $tag` discriminator in `wasm/runtime.wat`, replacing the tagged i31 char encoding. The `$tag` field is always `0` and is never read — it exists only because binaryen's `wasm-as` structurally deduplicates single-i32 struct types, and `$primitive` already occupies that shape; the discriminator gives `$char` its own type identity.
- **ADDED** singleton struct instances for the five specials. Each becomes its own empty struct type (`$false-type`, `$true-type`, `$nil-type`, `$eof-type`, `$void-type`), instantiated once at module-init as a global. `ref.eq` comparisons continue to work identically because each global holds a unique heap reference.
- **ADDED** a 128-element ASCII char intern table populated at startup so character operations on ASCII text (the overwhelmingly common case — string iteration, char predicates, parsers, the reader) stay allocation-free. Non-ASCII chars allocate on demand.
- **MODIFIED** `$make-fixnum` to encode directly via `ref.i31 (local.get $n)` — no shift.
- **MODIFIED** `$fixnum-value` to decode directly via `i31.get_s (local.get $v)` — no shift.
- **MODIFIED** `$is-fixnum` to simplify to `ref.test (ref i31) (local.get $v)` — one check instead of two.
- **MODIFIED** `$make-char`, `$char-codepoint`, `$is-char` to use the new struct type.
- **MODIFIED** `$make-fixnum-or-float` range check to `[-2^30, 2^30-1]`.
- **MODIFIED** `$f64-to-ece-number`, `$wrap-i32`, `$wrap-f64` range checks to match.
- **MODIFIED** `$is-integer` to return `#t` for finite float-box values holding whole numbers (R7RS-compliant, and required to avoid an infinite loop in the prelude's `(number->string n)` when `n` is the result of integer `quotient` via f64 `/`). The CL-side `integer?` primitive is updated in lockstep.
- **MODIFIED** `truncate`, `floor`, `integer->char` primitive dispatches to use `$f64-to-ece-number` / `$to-f64` + range validation instead of passing the raw output of `$safe-trunc-i32` to `$make-fixnum`. The old code silently corrupted values outside `[-2^30, 2^30-1]` via i31 sign-bit overflow; with identity encoding this corruption became exposed. `integer->char` also validates the Unicode scalar range `[0, 0x10FFFF]`.
- **AUDITED** every direct `i31.get_s` / `i31.get_u` usage in `runtime.wat` for implicit assumptions about the shift encoding — such sites are updated or documented.
- **ADDED** `tests/ece/common/test-fixnum-full-range.scm` — regression tests that exercise values in the new 30-bit band `[2^29, 2^30-1]` (and the mirrored negative band) and verify they behave as fixnums: identity through `+`/`-`, equality, arithmetic-shift round-trips, and display round-trips.
- **BOOTSTRAP** — after the runtime change, `make bootstrap` is run and the refreshed `.ecec` files are committed. The `.ecec` serialization format does not change (fixnums still serialize as decimal integers, chars still as codepoints), so this is a pure runtime-representation change.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `wasm-runtime` — changes the value-tagging scheme used inside the runtime. Fixnums now use the full `[-2^30, 2^30-1]` range instead of `[-2^29, 2^29-1]`. Chars and the five special singletons now live as heap-allocated structs (chars with an ASCII intern fast path) instead of tagged i31 values.

## Impact

- **Affected code:**
  - `wasm/runtime.wat` — new `$char` struct, new special singleton globals, rewritten `$make-fixnum`/`$fixnum-value`/`$is-fixnum`/`$make-char`/`$char-codepoint`/`$is-char`/`$make-fixnum-or-float`/`$f64-to-ece-number`, ASCII intern table setup, audited i31 usages.
  - `tests/ece/common/test-fixnum-full-range.scm` — new regression test file exercising the widened range.
  - `bootstrap/*.ecec` — regenerated via `make bootstrap`; format unchanged but the refreshed files include any subtle compile-time shifts from the updated runtime behaviour.
- **Affected workflows:** any ECE code that creates chars, uses the five specials, or produces integers in `[2^29, 2^30-1]`. All three are very common. The specials in particular are created every time any conditional runs (`#f`/`#t`) or any list terminates (`nil`).
- **Performance:**
  - Fixnum creation/read: slightly faster (no shift).
  - Fixnum type test: slightly faster (one `ref.test` instead of `ref.test` + `i32.and`).
  - Arithmetic in the 30-bit band: much faster (was float-box allocation per result, now direct i31).
  - Char creation for ASCII: same cost as before (intern table lookup vs. i31 tag, both are O(1) and allocation-free).
  - Char creation for non-ASCII: slower (heap alloc vs. i31 tag). Non-ASCII chars are rare in ECE workloads today; if this changes, we can extend the intern table or add a small per-module cache.
  - Special comparisons: same cost (`ref.eq` of a global vs. `ref.eq` of an i31 — both compile to pointer equality).
- **Test plan:**
  - `test-fixnum-full-range.scm` — new file exercising values in `[2^29, 2^30-1]` and `[-2^30, -2^29-1]`, via identity, arithmetic, comparison, and display.
  - `test-bitwise-large.scm` — PR #150's large-integer coverage must still pass byte-for-byte.
  - `test-bitwise-variadic.scm` — PR #152's variadic coverage must still pass.
  - `test-sha1.scm` — digest must still match RFC 3174 test vector `a9993e364706816aba3e25717850c26c9cd0d89d`.
  - `test-strings.scm`, `test-types.scm`, `test-misc.scm` — char handling must be unchanged.
  - Full `make test` suite (rove, ece, wasm, conformance, golden, web-server, web-apps) passes with zero regressions.
- **Rollback:** single-commit revert of `wasm/runtime.wat` and `bootstrap/*.ecec`. Low risk because the change is self-contained in the runtime — no .ecec format change, no CL-side change, no user-visible API change.
- **Follow-up:** once merged, delete the `project_wasm_fixnum_range.md` memory — the pitfall is gone.
