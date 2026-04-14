## Why

PR #150 fixed the WASM runtime's large-integer handling so SHA-1 and other 32-bit-arithmetic algorithms would work cross-runtime. But during that investigation, I found another latent bug that I worked around rather than fixing structurally: **the WASM primitive dispatch for `bitwise-and`, `bitwise-or`, and `bitwise-xor` only reads `arg1` and `arg2`. Third and subsequent arguments are silently dropped.**

The CL side implements these primitives as `(cl:apply cl:logand args)` / `cl:logior` / `cl:logxor`, which are genuinely variadic. So ECE code like `(bitwise-xor b c d)` works correctly on CL and silently produces wrong results on WASM — no error, no warning, just the first two arguments XORed together.

SHA-1 uses 3-way XOR in `sha1/f` (rounds 20-39 and 60-79) and 4-way XOR in `sha1/extend-words!` (the message schedule). PR #150's workaround was to rewrite those call sites as nested binary calls: `(bitwise-xor b (bitwise-xor c d))`. That works but:

1. It makes the SHA-1 source harder to read — the algorithm is specified in terms of variadic XOR.
2. It doesn't fix the footgun. Any future ECE code that uses variadic bitwise on WASM will silently break the same way.
3. There's no test in the suite that catches this — the entire existing test surface uses binary calls, so the bug is invisible to regression testing.

This proposal fixes the dispatch arms to actually be variadic, adds test coverage that would have caught the original bug, and reverts the SHA-1 workaround back to the natural form.

## What Changes

- **ADDED** three helpers in `wasm/runtime.wat` — `$fold-bitwise-and`, `$fold-bitwise-or`, `$fold-bitwise-xor`. Each iterates over the args list (shape modelled on the existing `$fold-add`), accumulates the result in an i32 via `$trunc-to-i32-wrap` + `i32.and`/`i32.or`/`i32.xor`, and returns via `$make-fixnum-or-float`. Zero-arg identity elements match CL: `(bitwise-and) = -1`, `(bitwise-or) = 0`, `(bitwise-xor) = 0`.
- **MODIFIED** the primitive dispatch arms for 76 (`bitwise-and`), 77 (`bitwise-or`), and 78 (`bitwise-xor`) in `wasm/runtime.wat` — replace the hand-written binary versions with calls to the new fold helpers.
- **ADDED** `tests/ece/common/test-bitwise-variadic.scm` — cross-runtime coverage for 0, 1, 2, 3, 4, and 5-arg forms of each primitive. Uses both fixnum and float-box inputs. Zero-arg cases assert the identity elements. This is the regression test that would have caught the bug originally.
- **REVERTED** the SHA-1 nested-binary workaround in `src/sha1.scm`. `sha1/f` rounds 2 and 4 go back to `(bitwise-xor b c d)`. `sha1/extend-words!` goes back to the natural 4-way form. Header comment about binary-only dispatch is removed.
- **BOOTSTRAP** — no bootstrap regen needed. Changes are in the WASM runtime and ECE source files, not in the CL side or compiled .ecec files.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `wasm-runtime` — extends the specified behaviour of `bitwise-and`, `bitwise-or`, and `bitwise-xor` primitives to match the CL side's variadic semantics (including zero-arg identity elements), rather than the previous binary-only behaviour.

## Impact

- **Affected code:**
  - `wasm/runtime.wat` — three new fold helpers + three dispatch arm rewrites (~80 lines net)
  - `tests/ece/common/test-bitwise-variadic.scm` — new file (~60 lines)
  - `src/sha1.scm` — revert ~15 lines back to variadic form
- **Affected workflows:** any ECE code that uses multi-way bitwise operations. Currently only SHA-1 exercises this, but future hash/crypto/bitmask/parser code is unblocked.
- **Performance:** neutral. The 2-arg case does one extra function call through the fold helper (vs the old inline dispatch), but the hot path is identical otherwise. For 3+ arg calls, the new path is strictly correct where the old path was silently wrong.
- **Test plan:**
  - `test-bitwise-variadic.scm` must pass identically on CL and WASM for all argument counts and both fixnum/float-box inputs.
  - `test-sha1.scm` continues to pass on both runtimes after the sha1.scm revert.
  - `test-bitwise-large.scm` (from PR #150) continues to pass.
  - Full `make test` suite passes with zero regressions.
- **Rollback:** single-commit revert of `wasm/runtime.wat` (and optionally re-apply the SHA-1 nested-binary workaround). Low risk because the old binary path is preserved as a degenerate case inside the new fold helpers (2-arg calls reduce to identical behaviour).
- **Relationship to PR #150:** completes the cleanup PR #150 couldn't fit. Unblocks future code that needs variadic bitwise. Lets the SHA-1 source read the way the RFC specifies it.
