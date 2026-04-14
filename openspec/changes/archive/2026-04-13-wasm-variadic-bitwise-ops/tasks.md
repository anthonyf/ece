## 1. Fold helpers in wasm/runtime.wat

- [x] 1.1 Add `$fold-bitwise-and` near `$fold-add` / `$fold-mul`. Signature: `(param $args (ref null eq)) (result (ref null eq))`. Body:
  - Initialize `$acc` (i32 local) to `-1`
  - Loop over `$args` via `$xcar`/`$xcdr`, exit when the list is null
  - Each iteration: `$acc = i32.and $acc (trunc-to-i32-wrap (to-f64 (xcar cur)))`
  - Return `$make-fixnum-or-float $acc`
- [x] 1.2 Add `$fold-bitwise-or` with the same shape. Identity = `0`, op = `i32.or`.
- [x] 1.3 Add `$fold-bitwise-xor` with the same shape. Identity = `0`, op = `i32.xor`.

## 2. Primitive dispatch updates

- [x] 2.1 Replace the dispatch arm for primitive 76 (`bitwise-and`) in `$apply-primitive` with a call to `$fold-bitwise-and` on the full `$args` list.
- [x] 2.2 Replace the dispatch arm for primitive 77 (`bitwise-or`) with a call to `$fold-bitwise-or`.
- [x] 2.3 Replace the dispatch arm for primitive 78 (`bitwise-xor`) with a call to `$fold-bitwise-xor`.
- [x] 2.4 Verify that primitives 79 (`bitwise-not`, unary) and 80 (`arithmetic-shift`, binary) are unchanged — they're not variadic.

## 3. Regression tests

- [x] 3.1 Create `tests/ece/common/test-bitwise-variadic.scm` with tests for each of the three variadic primitives, covering:
  - 0 arguments (identity element assertions)
  - 1 argument (returns the argument unchanged)
  - 2 arguments (matches the existing binary behaviour)
  - 3 arguments (catches the pre-fix silent-drop bug)
  - 4 arguments (SHA-1 message-schedule shape)
  - Mixed fixnum + float-box inputs (verify the dispatch handles both representations uniformly across args)
  - Large unsigned values (the SHA-1 round constants) — compared via byte extraction to avoid the signed-vs-unsigned divergence documented in PR #150
- [x] 3.2 Run `test-bitwise-variadic.scm` under `make test-ece` (CL) and `make test-wasm` (WASM). They MUST pass identically on both.

## 4. Revert SHA-1 nested-binary workaround

- [x] 4.1 In `src/sha1.scm`, revert `sha1/f` rounds 2 (t 20-39) and 4 (t 60-79) back to the natural form: `(bitwise-xor b c d)`.
- [x] 4.2 Revert `sha1/extend-words!` back to the natural 4-way form: `(bitwise-xor (vector-ref w (- t 3)) (vector-ref w (- t 8)) (vector-ref w (- t 14)) (vector-ref w (- t 16)))`.
- [x] 4.3 Remove the explanatory comments referring to "nested binary" and "WASM primitive dispatch is binary only" from both functions' docstrings.

## 5. Validation

- [x] 5.1 `make test-ece` — 480+ ECE tests pass with 0 failures.
- [x] 5.2 `make test-wasm` — all WASM tests pass, specifically `test-bitwise-variadic.scm` new coverage and the reverted `test-sha1.scm` still passes byte-for-byte.
- [x] 5.3 `make test-bitwise-large` regression check — PR #150's coverage continues to pass (since the fold helpers degrade to the same 2-arg behaviour for binary calls).
- [x] 5.4 Full `make test` — every suite (rove, ece, wasm, conformance, golden, web-server, web-apps) passes with zero regressions.
- [x] 5.5 `make ece` — CL binary rebuilds successfully.

## 6. Archive and commit

- [x] 6.1 Archive the change in-PR BEFORE merging per the archive-before-merge rule.
- [x] 6.2 Commit with a message naming the fix scope and mentioning the SHA-1 revert.
- [x] 6.3 Open a PR with:
  - A short summary pointing at PR #150's workaround as the motivation
  - The list of modified primitives (76, 77, 78)
  - The list of new helpers
  - Confirmation that SHA-1 continues to work with the natural variadic form
