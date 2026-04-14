## 1. Helper

- [x] 1.1 Add `$make-fixnum-or-float` in `wasm/runtime.wat` near `$make-fixnum`. Signature: `(param $n i32) (result (ref null eq))`. Behaviour:
  - If `$n` is in `[-536870912, 536870911]` = `[-2^29, 2^29-1]` (the actual i31-encoded fixnum range), return `$make-fixnum $n`.
  - Otherwise, return `(struct.new $float-box (f64.convert_i32_s $n))`.
- [x] 1.2 Add a short comment above the helper explaining the fixnum range, the purpose (overflow-safe boxing for bitwise-op outputs), and that it mirrors the logic in `$f64-to-ece-number` for the i32 input path. Additionally introduce `$trunc-to-i32-wrap` (i64-backed f64→i32 preserving low 32 bits) and `$arith-shift-i32` (shift-count-clamped) as companion helpers.

## 2. Primitive dispatch updates

- [x] 2.1 Rewrite the dispatch arm for primitive 77 (`bitwise-or`). Read both arguments via `$trunc-to-i32-wrap + $to-f64`, compute `i32.or`, return via `$make-fixnum-or-float`.
- [x] 2.2 Same rewrite for primitive 78 (`bitwise-xor`). `i32.xor` body.
- [x] 2.3 Same rewrite for primitive 79 (`bitwise-not`). Read single argument via `$trunc-to-i32-wrap + $to-f64`, compute `i32.xor $n (i32.const -1)`, return via `$make-fixnum-or-float`.
- [x] 2.4 Rewrite the dispatch arm for primitive 80 (`arithmetic-shift`). Delegate to the new `$arith-shift-i32` helper so shift counts of 32+ clamp to a full-width result (WASM natively masks shift counts to the low 5 bits). Value argument read via `$trunc-to-i32-wrap + $to-f64`; shift-count read via `$fixnum-value`.
- [x] 2.5 Also update primitive 76 (`bitwise-and`) to use `$trunc-to-i32-wrap` — its old `$safe-trunc-i32` path silently clamped inputs above 2^31-1, so it was wrong for SHA-1 round constants even though no existing test exercised that. The five bitwise primitives now share a consistent dispatch shape.

## 3. New regression tests

- [x] 3.1 Create `tests/ece/common/test-bitwise-large.scm` with tests exercising each of the five bitwise primitives on inputs that:
  - (a) Both fit in fixnum range `[-2^29, 2^29-1]`.
  - (b) One fits and one is a float-box (value above 2^29).
  - (c) Both are float-boxes.
  - (d) Result fits in fixnum range.
  - (e) Result overflows fixnum range.
  - (f) Result overflows signed 32-bit range on the negative side.
- [x] 3.2 Add a cross-runtime sanity test that uses specific SHA-1 round-constant patterns. Compute `(bitwise-xor 0x5A827999 0xC3D2E1F0)` (using decimal literals), `(bitwise-or 0x67452301 0xEFCDAB89)`, etc. Verify the results match what the CL runtime produces. Scoped to byte-extracted outputs because direct comparison of large-unsigned results diverges between CL (bignum) and WASM (signed i32).
- [x] 3.3 Add an `arithmetic-shift`-specific test block: left-shift a byte into each of bit-positions 0, 8, 16, 24; verify the result.
- [x] 3.4 Run the new tests under `make test-ece` (CL) and `make test-wasm` (WASM). They pass identically on both: 701/701 WASM, 480/480 ECE, SHA-1 moved back to common and runs cross-runtime.

## 4. SHA-1 test migration back to common/

- [x] 4.1 Move `tests/ece/cl-only/test-sha1.scm` → `tests/ece/common/test-sha1.scm`.
- [x] 4.2 Move `tests/ece/cl-only/test-sha1-base64-websocket.scm`'s content back into `tests/ece/common/test-base64.scm` as the final test in that file, restoring the structure from before PR #149 gated it.
- [x] 4.3 Delete the now-empty `tests/ece/cl-only/test-sha1-base64-websocket.scm`.
- [x] 4.4 Update `Makefile`'s `WASM_TEST_SRCS` to re-add `src/sha1.scm` between `src/base64.scm` and the test file glob. Update the comment on that line accordingly.
- [x] 4.5 Update `src/sha1.scm`'s header: remove the long "Runtime support" section explaining the WASM limitation (no longer applies), keep the security caveats about collision resistance.

## 5. Validation

- [x] 5.1 Run `make test-ece` — 480/480 ECE tests pass with 0 failures (842 assertions).
- [x] 5.2 Run `make test-wasm` — 701/701 WASM tests pass, specifically the sha1 and base64+sha1 tests now run on WASM and pass.
- [x] 5.3 Run full `make test` — every suite (rove 143/143, ece 842 assertions/0 fail, wasm 701/0, conformance 162/0, web-apps 6/0) passes with zero regressions.
- [x] 5.4 Run `make ece` and verify the binary rebuilds successfully (WASM rebuild happens via `make wasm` as part of the full suite).

## 6. Archive and commit

- [x] 6.1 Archive this change in-PR BEFORE merging (done via git mv to `archive/2026-04-13-wasm-bitwise-large-integers/`).
- [x] 6.2 Commit with a message naming the fix scope.
- [x] 6.3 PR #150 updated with implementation summary, root-cause analysis, and cross-runtime validation.
