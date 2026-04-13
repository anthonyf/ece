## Context

ECE's WASM runtime uses two numeric representations:

- **Fixnums**: `i31ref` values encoded as `(n << 1)` via `$make-fixnum` (`wasm/runtime.wat:248`). The `<< 1` reserves bit 0 as a type tag (0 = fixnum). That leaves 30 bits of value plus one sign bit, so the fixnum range is `[-2^30, 2^30-1]` = `[-1073741824, 1073741823]`.
- **Boxed floats**: `$float-box` structs wrapping an `f64` (`wasm/runtime.wat:84-86`). Used for non-integer numbers, integer literals that don't fit in fixnum range, and results of arithmetic that overflows fixnum range.

`$f64-to-ece-number` (`wasm/runtime.wat:560-572`) is the single place that decides which representation a given number gets: if the f64 is an integer and fits in fixnum range, return a fixnum; otherwise return a float-box. This is how integer literals in ECE source (e.g., `1518500249`) end up as float-boxes when they load into the image — the reader produces an f64, then `$f64-to-ece-number` routes it.

The asymmetry in the bitwise primitives arose because `bitwise-and` (primitive 76) was explicitly written to support this dual representation — its dispatch arm converts both inputs via `$to-f64` + `$safe-trunc-i32`, which accept either fixnums or float-boxes and truncate to an `i32` for the bitwise operation. Lines 4203-4206:

```wat
(if (i32.eq (local.get $id) (i32.const 76))
  (then (return (call $make-fixnum (i32.and
    (call $safe-trunc-i32 (call $to-f64 (call $arg1 (local.get $args))))
    (call $safe-trunc-i32 (call $to-f64 (call $arg2 (local.get $args)))))))))
```

But primitives 77-80 (`bitwise-or`, `bitwise-xor`, `bitwise-not`, `arithmetic-shift`) were not updated in the same pattern. They cast arguments directly to `(ref i31)` and read the value via `$fixnum-value`. Lines 4207-4232:

```wat
(if (i32.eq (local.get $id) (i32.const 77))
  (then (return (call $make-fixnum (i32.or
    (call $fixnum-value (ref.cast (ref i31) (call $arg1 (local.get $args))))
    (call $fixnum-value (ref.cast (ref i31) (call $arg2 (local.get $args)))))))))
```

If either argument is a float-box, the `ref.cast` traps. If both are fixnums but the *result* exceeds 30 bits, `$make-fixnum` silently truncates (`(i32.shl n 1)` discards the high bit in the i31). Either way, 32-bit arithmetic breaks in subtle ways:

- Sometimes crashes (with a runtime error from the cast trap).
- Sometimes returns wrong values (when the result overflows 30 bits and `$make-fixnum` truncates).
- `arithmetic-shift`'s `i32.shl` is a full 32-bit shift, but the result goes through `$make-fixnum` anyway, so high bits are lost.

This was caught when SHA-1 — which needs 32-bit arithmetic end-to-end — produced wrong digests on WASM despite passing on CL. CI failure logs from PR #149 show `sha1("")` coming back as `fb33ee8f...` instead of the RFC 3174 canonical `da39a3ee...`.

## Goals / Non-Goals

**Goals:**
- `bitwise-or`, `bitwise-xor`, `bitwise-not`, and `arithmetic-shift` behave identically on CL and WASM for any integer inputs in the range `[-2^31, 2^31-1]` (comfortably inside f64's `[-2^53, 2^53]` exact-integer range).
- The contract for these primitives is: accept any ECE integer (fixnum or float-box), compute the 32-bit bitwise result, and return an ECE integer of whichever representation fits the result.
- A dedicated test suite exercises the new behavior on both runtimes with identical expectations, so future regressions are caught before they reach CI's sha1 tests.
- After this change, SHA-1 tests can move back from `tests/ece/cl-only/` to `tests/ece/common/` and pass on both runtimes.

**Non-Goals:**
- No changes to the CL runtime. CL uses bignums and already handles 32-bit arithmetic correctly. The primitives (`cl:logand`, `cl:logior`, `cl:logxor`, `cl:lognot`, `cl:ash`) don't need any touches.
- No expansion of ECE's integer range beyond what f64 can exactly represent. Operations on values outside `[-2^53, 2^53]` remain implementation-defined.
- No introduction of a dedicated bignum type in WASM. Float-boxes are the existing fallback for large integers and continue to be the mechanism here.
- No changes to `$make-fixnum` or `$fixnum-value`. Those are low-level primitives used by many parts of the runtime; changing them is broader scope than this fix needs. Instead, a new helper `$make-fixnum-or-float` handles the overflow-aware boxing at the bitwise-op layer.
- No general audit of other primitives that might have the same dual-representation bug. If any exist (e.g., arithmetic `+`, `-`, `*`, `/`), they're out of scope for this change. The investigation that surfaced this issue was specifically the bitwise ops.

## Decisions

### 1. Introduce `$make-fixnum-or-float` instead of modifying `$make-fixnum`

**Choice:** Add a new helper function `$make-fixnum-or-float` that takes an `i32`, checks whether it fits in the 30-bit fixnum range, and either calls `$make-fixnum` or boxes as an f64-backed float. Use this helper from the four affected primitive dispatch arms. Do not modify the existing `$make-fixnum`.

**Rationale:** `$make-fixnum` is called from many places in the runtime (not just bitwise ops). Most callers know statically that their values fit in fixnum range (character codes, array indices, length counts). Making `$make-fixnum` itself branch on range would add a runtime cost to every call for a minority that needs the overflow check. A dedicated helper keeps the hot path clean and the overflow handling explicit at the site that needs it.

**Alternatives considered:**
- **Modify `$make-fixnum` to always check range.** Rejected on hot-path grounds.
- **Inline the overflow check at each of the four dispatch arms.** Rejected — duplicated code, hard to audit, easy to introduce inconsistency.

### 2. Dual-representation reads via `$safe-trunc-i32` + `$to-f64`

**Choice:** Each of the four affected dispatch arms reads its integer arguments via the same pattern `bitwise-and` already uses: `$safe-trunc-i32` of `$to-f64` of the argument. This accepts both fixnum and float-box inputs, returning an `i32` suitable for the bitwise operation.

**Rationale:** Consistency with the existing working primitive. `$to-f64` and `$safe-trunc-i32` already exist and are battle-tested. No new argument-dispatch logic needed. The cost is one extra function call per argument (small), which is a trivial overhead for bitwise operations that are already cheap at the instruction level.

**Alternatives considered:**
- **Write a type-dispatching helper** that checks `is-fixnum` vs `is-float-box` and reads accordingly, avoiding the `f64` round-trip for fixnum inputs. Rejected — the f64 round-trip is cheap and the dispatch logic would duplicate what `$to-f64` already does. Premature optimization.

### 3. Keep `arithmetic-shift` semantics intact for 32-bit results

**Choice:** `arithmetic-shift` reads its first argument via `$safe-trunc-i32 + $to-f64` (same as above), reads its shift count as a regular fixnum (it's always small, rarely > 63), uses `i32.shl` or `i32.shr_s` in the same signed direction as today, and routes the result through `$make-fixnum-or-float`.

**Rationale:** The signed shift behavior is what standard Scheme `arithmetic-shift` specifies (negative counts mean right shift, result preserves sign for arithmetic shift). Changing the shift operator would break other callers. The only bug to fix is the *output* path — make-fixnum truncation — which is exactly what `$make-fixnum-or-float` addresses.

**Alternatives considered:**
- **Switch to `i32.shr_u` (unsigned right shift)** to match some interpretations of 32-bit bitwise semantics. Rejected — changes observable behavior for callers that rely on arithmetic (sign-preserving) shift.

### 4. Promotion to float-box on overflow, not wrap-around

**Choice:** `$make-fixnum-or-float` promotes to an f64 float-box when the `i32` value is outside `[-2^30, 2^30-1]`. The float-box holds the exact integer value, because f64 exactly represents all i32 values (they're well within the 2^53-bit integer precision of f64).

**Rationale:** Matches how integer literals are stored today — the reader produces f64, `$f64-to-ece-number` routes to fixnum or float-box based on range. Keeping the same representation at the output of bitwise ops means no surprises for downstream code: `(bitwise-or 1 2)` returns a fixnum, `(bitwise-or 0x80000000 1)` returns a float-box, both are valid ECE integers that other ops handle.

**Tradeoff:** A sequence of bitwise ops on large integers might allocate a float-box per intermediate result. Not ideal for tight loops, but acceptable for algorithmic correctness. SHA-1's inner loop does ~5 allocations per round, so 400 per block, ~6000 per SHA-1 call for a small input. That's noticeable but tolerable.

**Alternatives considered:**
- **Wrap-around to fixnum by masking** (e.g., `n & 0x7FFFFFFF`) to avoid allocation. Rejected — silently wrong results are worse than a small perf cost.
- **Return a tagged i32 directly** using a different fixnum encoding that has more range. Rejected — requires runtime-wide refactor of the fixnum representation.

## Risks / Trade-offs

- **[Allocation cost in tight loops]** The overflow promotion path allocates a `$float-box` per result. For algorithms that produce many large-integer intermediates (like SHA-1), this is a visible allocation count. → **Mitigation**: accept the cost for correctness. If a hot-path benchmark shows it's a real problem, a future change can investigate inlined fixnum-wider types or a pool-allocated float-box free list. Not blocking.
- **[Surface area of the fix is narrow]** This change only touches the four specific primitives. If other primitives have the same bug (e.g., `+` and `-` on large integers), they're not fixed here. → **Mitigation**: the investigation that surfaced this was scoped to bitwise ops because that's what SHA-1 exercised. A broader audit would be a separate change. File it as a follow-up if needed.
- **[Test coverage depth]** The new `test-bitwise-large.scm` checks representative patterns, but bitwise primitives have a large input space. Exhaustive testing is impractical. → **Mitigation**: use fixed vectors + randomized cross-runtime comparison (generate N random inputs, compute on both CL and WASM, assert equality). Even 100 random cases catch most realistic bugs.
- **[Interaction with `$make-fixnum` callers]** Some parts of the runtime call `$make-fixnum` directly and assume the result is always a fixnum. These callers are unchanged by this proposal because they operate on values that are guaranteed to fit in 30-bit range (indices, counts). But a future audit that blurs this boundary could cause type confusion. → **Mitigation**: document `$make-fixnum-or-float` clearly as "for primitives whose output can overflow"; leave `$make-fixnum` as-is for "I already know this fits."
- **[Bootstrap and build interaction]** `wasm/runtime.wat` changes require `make wasm` to rebuild `wasm/runtime.wasm`, but no `make bootstrap` is needed because the zone files are unchanged. → **Mitigation**: standard `make test` covers both. CI builds `wasm` automatically.

## Migration Plan

Not applicable. Internal runtime fix. Any ECE code that was using the affected primitives on large integers was producing wrong results, so this change is strictly a correctness improvement — there's no "old behavior" to preserve.

The only migration-ish item is reshuffling the SHA-1 tests: move them back from `tests/ece/cl-only/` to `tests/ece/common/` and re-add `src/sha1.scm` to `WASM_TEST_SRCS`. These are file moves plus a Makefile edit. Both happen in the same PR as the runtime fix.

## Open Questions

- **Do `+`, `-`, `*`, `/` have the same bug for large integers?** Worth a quick audit during implementation. If yes, the fix is the same pattern (`$safe-trunc-i32` on inputs, `$make-fixnum-or-float` on outputs — or whatever analogue applies to each op's arithmetic). But each op has different overflow semantics, so this deserves its own investigation. Defer to a follow-up change unless the audit reveals a bug serious enough to ship alongside this one.
- **Should `$make-fixnum-or-float` live in `runtime.wat` or be inlined into each dispatch arm?** Inlining saves a function call but duplicates the range-check logic. Rough benchmarks during implementation will settle this. Default: use a helper function (cleaner).
- **Where should the new `test-bitwise-large.scm` live?** `tests/ece/common/` is the obvious place since it tests platform-independent semantics. Confirm the test framework runs it on both CL and WASM.
- **What's the exact f64 integer representable range?** 2^53 = 9007199254740992. Well beyond any 32-bit value, so this isn't a concern for the bitwise primitives. Document in the helper's comment that the `i32` input is always exactly representable.
