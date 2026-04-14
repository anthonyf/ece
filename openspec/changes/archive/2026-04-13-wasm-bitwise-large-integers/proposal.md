## Why

PR #149 (`sha1-base64-utilities`) added a pure-ECE SHA-1 implementation that works correctly on the CL runtime but produces wrong digests on the WASM runtime. Investigation revealed that ECE's WASM runtime has **incomplete large-integer support in its bitwise primitives**. Only `bitwise-and` handles the dual fixnum/float-box representation correctly; `bitwise-or`, `bitwise-xor`, `bitwise-not`, and `arithmetic-shift` cast their inputs unconditionally to `(ref i31)`, silently corrupting values that had been boxed as f64 floats because they exceeded the 30-bit fixnum range.

Concretely:

- ECE WASM fixnums are `i31ref`s encoded as `(n << 1)` via `$make-fixnum` (`wasm/runtime.wat:248`). Valid fixnum range is `[-2^30, 2^30-1]`. Anything outside that range is boxed as an f64 via `$f64-to-ece-number` (`wasm/runtime.wat:560`).
- `bitwise-and` (primitive 76, `wasm/runtime.wat:4203-4206`) correctly uses `$safe-trunc-i32` + `$to-f64` on each argument, so it accepts both fixnums and float-boxes and returns a result of whichever type fits.
- `bitwise-or` (77), `bitwise-xor` (78), `bitwise-not` (79), and `arithmetic-shift` (80) all do `(ref.cast (ref i31) arg)` + `$fixnum-value`. If the argument is an f64 float-box, the cast traps; if the argument happens to be a fixnum but the *result* overflows 30 bits, `$make-fixnum` silently truncates the top bits.
- SHA-1 and any other algorithm that does 32-bit arithmetic hits both problems constantly: its round constants (e.g., `0x5A827999 = 1518500249`) are float-boxes, and its intermediate values (e.g., `byte << 24`) overflow 30 bits. The algorithm runs without crashing but produces wrong output.

PR #149's short-term fix was to gate SHA-1 tests to `tests/ece/cl-only/` and document the WASM limitation in `src/sha1.scm`'s header. That unblocks the CL-hosted ece-serve use case where SHA-1 runs on the host, but it leaves a real correctness gap: any ECE code running on WASM (sandbox, browser tests) that wants 32-bit arithmetic is broken. This change is the structural fix.

## What Changes

- **MODIFIED** `wasm/runtime.wat` — rewrite the dispatch arms for primitives 77 (`bitwise-or`), 78 (`bitwise-xor`), 79 (`bitwise-not`), and 80 (`arithmetic-shift`) so they:
  1. Read their integer arguments via `$safe-trunc-i32 + $to-f64` (the same pattern `bitwise-and` already uses), accepting both fixnum and float-box inputs.
  2. Compute the result in `i32` space as today.
  3. Box the result via a new helper `$make-fixnum-or-float` (see below) that promotes to a float-box when the result exceeds the 30-bit signed range.
- **ADDED** a new helper `$make-fixnum-or-float` in `wasm/runtime.wat` near `$make-fixnum`. Signature: `(param $n i32) (result (ref null eq))`. Behavior: if `$n` fits in `[-2^30, 2^30-1]`, call `$make-fixnum`; otherwise, convert to `f64` via `f64.convert_i32_s` and return a `$float-box`. This mirrors `$f64-to-ece-number` for the i32 input path and keeps the dispatch uniform across the bitwise primitives.
- **ADDED** targeted regression tests under `tests/ece/common/test-bitwise-large.scm` that exercise each of the four primitives with:
  1. Both inputs small (fixnum × fixnum).
  2. One input large (fixnum × float-box).
  3. Both inputs large (float-box × float-box).
  4. Result overflowing 30 bits (forces the new promotion path).
  5. Result underflowing (negative, large magnitude).
  6. Specific SHA-1 round-constant patterns (`0x5A827999` ^ `0xC3D2E1F0`, etc.) cross-checked against the CL runtime's result.
- **MODIFIED** `tests/ece/cl-only/test-sha1.scm` — once the WASM fix lands, move this file back to `tests/ece/common/test-sha1.scm` so SHA-1 tests run on both runtimes.
- **MODIFIED** `tests/ece/cl-only/test-sha1-base64-websocket.scm` — same, move back to `tests/ece/common/test-base64.scm` as the `base64(sha1(...))` composition test.
- **MODIFIED** `Makefile` — add `src/sha1.scm` back to `WASM_TEST_SRCS` (between `src/base64.scm` and the test files).
- **MODIFIED** `src/sha1.scm` — remove the "Runtime support" section (the WASM limitation and its workaround) since it no longer applies. Keep the security caveats section.
- **BOOTSTRAP REGEN** — because this change modifies `wasm/runtime.wat`, the WASM binary must rebuild. This happens via `make wasm` as part of `make test`. No `make bootstrap` needed since the ECE zones are unchanged.
- **NO changes to the CL runtime** — ECE on CL uses bignums, which already handle 32-bit arithmetic correctly. The CL-side behavior is unchanged by this proposal.

## Capabilities

### New Capabilities
None. This is a correctness fix to existing primitives.

### Modified Capabilities
- `wasm-runtime` (or whichever capability owns the WASM primitive dispatch, to be determined during implementation) — extend the contract for the four affected bitwise primitives so they are specified to handle any ECE integer value, not just fixnum-representable ones. The spec changes to state that:
  - Input: any ECE integer in the representable range of `f64` (integers up to 2^53 are exactly representable).
  - Output: same range, with the correct bitwise semantics in 32-bit space.
  - Behavior for inputs outside `[-2^31, 2^31-1]` is implementation-defined (consistent with how CL handles bitwise ops on values that don't fit in 32 bits — the ops still work on the low 32 bits).

## Impact

- **Affected code**: `wasm/runtime.wat` (the four primitive dispatch arms + one new helper), tests in `tests/ece/common/`, and a small test-file move. Possibly a few lines in Makefile and `src/sha1.scm`.
- **Affected workflows**: any ECE code running on WASM that uses 32-bit arithmetic. Immediate beneficiaries: the SHA-1 module (can move back to `common/` tests), and any future code that needs 32-bit bit manipulation (hashes, CRCs, bitmask-heavy algorithms, pseudo-random generators using xorshift).
- **Performance**: neutral to slightly slower. The new dispatch path does one extra function call (`$make-fixnum-or-float` instead of `$make-fixnum`) and possibly one `f64.convert` + `struct.new` for float-box output in the overflow case. For SHA-1-size workloads this is negligible.
- **Test plan**:
  - New `test-bitwise-large.scm` runs on both CL and WASM and must pass identically on both.
  - SHA-1 tests (moved back to `common/`) must pass on both CL and WASM after the fix, with the same digest values.
  - Full `make test` suite (rove, ece, wasm, conformance, golden, web-server, web-apps) must pass with zero regressions.
- **Rollback**: single-commit revert of `wasm/runtime.wat`. Cheap and safe — the fix is isolated to four primitive dispatch arms plus one helper.
- **Relationship to other changes**: closes the WASM gap that `sha1-base64-utilities` (PR #149) documented. Unblocks any future WASM-side 32-bit algorithmic work. The `ece-serve` proposal is unaffected (ece-serve's WebSocket handshake runs on the CL host, not on WASM).
