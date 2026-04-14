## Context

ECE's WASM runtime uses two numeric representations:

- **Fixnums**: `i31ref` values encoded as `(n << 1)` via `$make-fixnum` (`wasm/runtime.wat:248`). The `<< 1` claims one bit of the i31 signed range, so the actual fixnum range is `[-2^29, 2^29-1]` = `[-536870912, 536870911]`. Values at or above `2^29` overflow the i31 sign bit and round-trip back as the wrong sign. (The earlier docs loosely called this `[-2^30, 2^30-1]`; that was wrong.)
- **Boxed floats**: `$float-box` structs wrapping an `f64` (`wasm/runtime.wat:84-86`). Used for non-integer numbers, integer literals that don't fit in fixnum range, and results of arithmetic that overflows fixnum range.

`$f64-to-ece-number` is the single place that decides which representation a given number gets. It was buggy before this change — it used `[-2^30, 2^30-1]` as the fixnum range, which created silently-corrupted fixnums for literal integers in `[2^29, 2^30-1]`. This change updates it to the correct `[-2^29, 2^29-1]`.

The asymmetry in the bitwise primitives arose because `bitwise-and` (primitive 76) read its inputs through `$safe-trunc-i32` + `$to-f64` (accepts either representation) while `bitwise-or`, `bitwise-xor`, `bitwise-not`, and `arithmetic-shift` cast their inputs directly to `(ref i31)` + `$fixnum-value`. Any float-box input would trap on the cast; any result exceeding the i31-encoded fixnum range would silently truncate through `$make-fixnum`.

When the investigation surfaced the bitwise-op bugs, it also turned up several neighbouring latent bugs that SHA-1 (the motivating use case) needs fixed in the same change:

- **`$safe-trunc-i32` clamping**: Clamps any f64 outside signed i32 range to the min/max of signed i32. SHA-1's round constants such as `0xEFCDAB89 = 4023233417` are `> 2^31 - 1`, so clamping silently corrupts them. A new `$trunc-to-i32-wrap` helper goes via i64 to preserve the low 32 bits verbatim.
- **`$ecec-read-number` integer overflow**: Used an `i32` accumulator, overflowing on literals `> 2^31 - 1`, and called `$make-fixnum` unconditionally. Now uses an i64 accumulator and routes through `$f64-to-ece-number`.
- **`$prim-number-to-string` float-box path**: Re-ran the fixnum digit loop after routing through `$make-fixnum`, silently corrupting any float-box that held an integer outside the fixnum range. Rewritten with an i64 digit-loop accumulator.
- **`$write-to-string-impl` missing float-box case**: Fell through to `"#?"` for float-box values. Added the explicit float-box dispatch.
- **WASM native shift-count masking**: `i32.shl` and `i32.shr_s` mask the shift count to the low 5 bits, so `(arithmetic-shift x -32)` is a no-op instead of zero. SHA-1's `sha1/u64-be` uses shift-32+ as part of its byte unpacking, which is where this bit us. A new `$arith-shift-i32` helper clamps shifts of `>= 32` to a full-width result.
- **SHA-1 rotl right-shift sign extension**: `(arithmetic-shift x -k)` on a value with bit 31 set uses `i32.shr_s`, which sign-extends. CL's `(ash x -k)` on a non-negative bignum zero-fills. For `sha1/rotl` this was a divergence; we fix it in `src/sha1.scm` by masking the right-shifted contribution with `((1 << n) - 1)` so only the intended `n` bits propagate.
- **Variadic bitwise ops on WASM**: The WASM primitive dispatch for `bitwise-or` / `bitwise-xor` / `bitwise-and` only reads two args. SHA-1 uses 3- and 4-way `bitwise-xor` and `bitwise-or`, which quietly drop arguments on WASM. Rather than expand the dispatch, we rewrite `src/sha1.scm` to use nested binary calls, which is portable.

`$f64-to-ece-number` is adjusted to the correct fixnum range, `$make-fixnum-or-float` is added alongside it for the i32-input path, and the bitwise primitive dispatch arms are rewritten to the shared `$trunc-to-i32-wrap + $make-fixnum-or-float` shape. All five bitwise primitives now pass the same 32-bit pipeline.

## Goals / Non-Goals

**Goals:**
- `bitwise-and`, `bitwise-or`, `bitwise-xor`, `bitwise-not`, and `arithmetic-shift` compute the correct 32-bit bit pattern on both runtimes for any ECE integer input with a value in `[-2^31, 2^32-1]` (the full signed-or-unsigned 32-bit range).
- A dedicated test suite exercises the new behaviour on both runtimes with identical expectations, so future regressions are caught before they reach CI's sha1 tests.
- After this change, SHA-1 tests move back from `tests/ece/cl-only/` to `tests/ece/common/` and pass on both runtimes.
- The WASM `.ecec` reader, printer, and error-message pipeline all handle integers across the full f64-exact range (up to 2^53), not just the fixnum range.

**Non-Goals:**
- No changes to the CL runtime. CL uses bignums and already handles 32-bit arithmetic correctly.
- No attempt to reconcile the "signed vs unsigned" numeric interpretation of i32 results on WASM with CL's bignum interpretation. For values outside `[-2^31, 2^31-1]`, WASM returns signed-i32-interpreted f64 values, CL returns non-negative bignum values — both have the same low 32 bits, but direct numeric comparison between runtimes will disagree. Algorithms that depend on bit-level equivalence (SHA-1, CRC, etc.) work; algorithms that do `(= x large-unsigned-literal)` on intermediate results don't, and that's documented.
- No new bignum type in WASM. Float-boxes remain the fallback for large integers.
- No general audit of other primitives that might have large-integer bugs (e.g., `+`, `-`, `*`, `/`, `modulo`). If any exist, they're out of scope.
- No expansion of the WASM primitive dispatch to handle variadic `bitwise-or` / `bitwise-xor` / `bitwise-and`. The SHA-1 call sites are rewritten to nested binary form.

## Decisions

### 1. Use a dedicated `$make-fixnum-or-float` for i32 outputs, not a modified `$make-fixnum`

**Choice:** Add a new helper that takes an i32, checks whether it fits in the `[-2^29, 2^29-1]` fixnum range, and either calls `$make-fixnum` or boxes as a float-box. Leave `$make-fixnum` as-is — its callers in the runtime all know statically that their values fit.

**Rationale:** Making `$make-fixnum` branch on range would add runtime cost to every call for a minority that needs the overflow check. A dedicated helper keeps the hot path clean.

### 2. Read inputs via `$trunc-to-i32-wrap` + `$to-f64`, not `$safe-trunc-i32`

**Choice:** The five bitwise primitives and the arithmetic-shift helper all read their integer arguments via `$trunc-to-i32-wrap` of `$to-f64`. The new wrap helper uses an i64 intermediate to avoid the trap on values outside signed i32 range (`$safe-trunc-i32` clamps, which silently corrupts the low 32 bits).

**Rationale:** `$safe-trunc-i32` is used by the arithmetic primitives (`+`, `-`, `*`) and should not be changed — the arithmetic paths produce wrong answers either way if the sum overflows i32, and clamping is at least deterministic. But for bitwise semantics the clamp is unambiguously wrong: we want the low 32 bits of the f64, which `i64.trunc_f64_s + i32.wrap_i64` gives us directly.

**Alternatives considered:**
- **Change `$safe-trunc-i32` to wrap-around.** Rejected — this would quietly change the behaviour of `$fold-add` et al. for overflowing sums, which is a separate (also wrong) behaviour that this change isn't trying to fix.
- **Inline the i64-wrap logic at each call site.** Rejected — duplicated code, hard to audit.

### 3. Fix `$f64-to-ece-number`'s fixnum range in the same change

**Choice:** Update `$f64-to-ece-number` to use `[-2^29, 2^29-1]` (matching `$wrap-i32` and the actual range of `$make-fixnum`'s encoding). Previously it used `[-2^30, 2^30-1]`, which created silently-corrupted fixnums for literals in `[2^29, 2^30-1]` and `[-2^30, -2^29-1]`.

**Rationale:** The latent-bug range directly affected the bitwise test values (SHA-1 round constants, hex-encoded byte patterns). Without this fix, a test literal like `1518500249` would round-trip as `-x` through the reader, making all assertions against it meaningless. The fix is a one-line change and has no downstream effect — values that were corrupted before are now correctly stored as float-boxes.

**Tradeoff:** Any existing `.ecec` files with literals in `[2^29, 2^30-1]` will round-trip differently after this change. In practice nothing relies on the corrupted behaviour — all affected values either hit `equal?` which goes via `$to-f64` (and sees the same numeric value), or the byte-extraction code that masks down to the low byte.

### 4. Keep `$arith-shift-i32`'s semantics CL-compatible for shift counts outside `[-31, 31]`

**Choice:** The helper clamps shifts of `>= 32` (left) to `0` and shifts of `<= -32` (right) to `shr_s x 31` (0 for non-negative inputs, -1 for negative). This matches CL's `ash` behaviour for a non-negative bignum shifted past its width and for a negative bignum shifted past the sign bit.

**Rationale:** WASM natively masks shift counts to the low 5 bits, so `(arithmetic-shift 24 -32)` returns 24 instead of 0. That's surprising and inconsistent with CL. SHA-1's `sha1/u64-be` exercises exactly this case. A small helper with clamping makes the ECE semantic portable across runtimes.

### 5. Fix SHA-1-specific divergences in `src/sha1.scm`, not in the WASM runtime

**Choice:** Two fixes to `src/sha1.scm`:
1. Replace variadic `bitwise-xor` / `bitwise-or` calls with nested binary forms (3- and 4-way XOR/OR). The WASM primitive dispatch only reads two arguments from the args list, silently dropping extras.
2. In `sha1/rotl`, mask the right-shifted contribution with `((1 << n) - 1)` so sign-extended bits from WASM's `i32.shr_s` don't pollute the rotated low bits.

**Rationale:** The variadic limitation is pre-existing WASM behaviour; expanding the dispatch to be variadic is a larger change and not needed for any other caller. The sign-extension issue in rotl is a consequence of the "signed vs unsigned i32 interpretation" gap that can't be fully bridged at the primitive level — the algorithm needs to explicitly say "this is an unsigned right shift". Both fixes are two- to five-line changes and keep the primitive surface minimal.

**Alternatives considered:**
- **Make the WASM bitwise primitive dispatch variadic.** Rejected — larger change, touches more code, not needed for any non-SHA-1 caller, and would slow the hot 2-ary path to support a rare variadic path.

## Risks / Trade-offs

- **Allocation cost in tight loops:** The float-box path allocates per overflow. SHA-1 does about 400 allocations per block. Acceptable for correctness.
- **Cross-runtime numeric divergence for values with bit 31 set:** CL and WASM disagree on the numeric interpretation of `0xEFCDAB89` — CL says `4023233417` (positive bignum), WASM says `-271733879` (signed i32). Byte-level operations match; direct numeric comparison does not. Documented. Test scaffolding avoids direct comparison of intermediates outside `[-2^31, 2^31-1]`.
- **Pre-existing latent bug in `$f64-to-ece-number` fixed as a side-effect:** The fixnum range correction moves a few literal integer values from "silently corrupted fixnum" to "correctly-stored float-box". This is strictly a correctness improvement but could theoretically change downstream behaviour. Running the full test suite (all 1500+ tests) with no regressions suggests nothing depends on the old corruption.
- **Write path changes:** `$prim-number-to-string` and `$write-to-string-impl` are both rewritten. Both are exercised by every test suite, and nothing regresses.

## Migration Plan

Not applicable. Internal runtime fix. Any ECE code that was relying on the old (incorrect) behaviour was already producing wrong results.

The SHA-1 tests move from `tests/ece/cl-only/` back to `tests/ece/common/`, `test-sha1-base64-websocket.scm`'s content is re-integrated into `test-base64.scm` as the final assertion, and `src/sha1.scm` is re-added to `WASM_TEST_SRCS`. All three are file-level edits in the same PR as the runtime fix.

## Open Questions

- **Do `+`, `-`, `*`, `/` have the same overflow issue for values outside the f64-exact range?** Probably, since `$safe-trunc-i32` is used by all of them for the all-int wrap path. But those primitives have different desired semantics (they should not modular-wrap — they should escalate to float automatically, which they basically do via `wrap-i32`'s out-of-range path). Defer to a follow-up audit.
- **Is the `sha1/rotl` masking approach a general pattern for portable right shifts?** Yes — any code that wants "unsigned right shift of a 32-bit word" needs to do this. A prelude-level helper would be cleaner than repeating the pattern in every client, but there's only one client today.
