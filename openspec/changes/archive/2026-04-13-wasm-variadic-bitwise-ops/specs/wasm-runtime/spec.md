## MODIFIED Requirements

### Requirement: WASM bitwise-and, bitwise-or, and bitwise-xor are fully variadic
The WASM implementations of `bitwise-and` (primitive 76), `bitwise-or` (primitive 77), and `bitwise-xor` (primitive 78) SHALL accept any number of arguments from 0 upward, folding them left-to-right through the corresponding i32 operation. The result is boxed via `$make-fixnum-or-float` and respects the same fixnum/float-box representation split as the rest of the runtime.

For 0 arguments, each primitive SHALL return its identity element: `-1` for `bitwise-and`, `0` for `bitwise-or`, `0` for `bitwise-xor`. This matches the Common Lisp side's behaviour (`cl:logand`, `cl:logior`, `cl:logxor` with no arguments return the same identities) and ensures cross-runtime parity.

For 1 argument, each primitive SHALL return the argument unchanged (after the fixnum/float-box normalisation implied by `$make-fixnum-or-float`).

For 2 arguments, the behaviour is identical to the previous binary-only dispatch — the existing `tests/ece/common/test-bitwise-large.scm` and `tests/ece/common/test-sha1.scm` assertions continue to hold byte-for-byte.

For 3 or more arguments, the fold applies the operation left-associatively: `(bitwise-op a b c d)` = `(bitwise-op (bitwise-op (bitwise-op a b) c) d)`. The low-32-bit bit pattern of the result matches the CL runtime's result byte-for-byte for inputs in `[-2^31, 2^32-1]`.

#### Scenario: Zero-arg bitwise-and returns -1
- **WHEN** `(bitwise-and)` is evaluated on the WASM runtime
- **THEN** the result SHALL be the ECE integer `-1`

#### Scenario: Zero-arg bitwise-or returns 0
- **WHEN** `(bitwise-or)` is evaluated on the WASM runtime
- **THEN** the result SHALL be the ECE integer `0`

#### Scenario: Zero-arg bitwise-xor returns 0
- **WHEN** `(bitwise-xor)` is evaluated on the WASM runtime
- **THEN** the result SHALL be the ECE integer `0`

#### Scenario: One-arg bitwise-xor returns the argument
- **WHEN** `(bitwise-xor 42)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `42`

#### Scenario: Three-arg bitwise-xor folds correctly
- **WHEN** `(bitwise-xor 5 3 6)` is evaluated on the WASM runtime
- **AND** the fold computes `5 XOR 3 = 6`, then `6 XOR 6 = 0`
- **THEN** the result SHALL be `0`
- **AND** the result SHALL NOT be `5 XOR 3 = 6` (the pre-fix WASM behaviour that silently dropped argument `6`)

#### Scenario: Four-arg bitwise-xor with mixed fixnum and float-box inputs
- **WHEN** `(bitwise-xor 1 2 4 8)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `15` (all four bits set)
- **WHEN** the same call is made with the larger inputs `(bitwise-xor 1518500249 1859775393 2400959708 3395469782)` — the SHA-1 round constants — two of which exceed `2^31-1`
- **THEN** the result SHALL match the CL runtime's `(logxor 1518500249 1859775393 2400959708 3395469782)` byte-for-byte (compared via `(bitwise-and result 255)` and friends, since direct numeric comparison diverges for bit-31-set values per the PR #150 spec)

#### Scenario: Three-arg bitwise-or folds correctly
- **WHEN** `(bitwise-or 1 2 4)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `7`

#### Scenario: Three-arg bitwise-and folds correctly
- **WHEN** `(bitwise-and 7 11 13)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `1` (the single bit common to all three)

#### Scenario: SHA-1 runs correctly after reverting the nested-binary workaround
- **WHEN** `src/sha1.scm` uses the natural variadic form `(bitwise-xor b c d)` in `sha1/f` and `(bitwise-xor w[t-3] w[t-8] w[t-14] w[t-16])` in `sha1/extend-words!`
- **AND** `(sha1-string "abc")` is evaluated on the WASM runtime
- **THEN** the digest SHALL match the RFC 3174 test vector `a9993e364706816aba3e25717850c26c9cd0d89d`

### Requirement: Fold helpers exist for each variadic bitwise primitive
Three helper functions `$fold-bitwise-and`, `$fold-bitwise-or`, and `$fold-bitwise-xor` SHALL exist in `wasm/runtime.wat`. Each has signature `(param $args (ref null eq)) (result (ref null eq))` and iterates over the args pair list accumulating the result in an `i32` local, starting from the primitive's identity element, reading each arg via `$to-f64` + `$trunc-to-i32-wrap`, combining with `i32.and` / `i32.or` / `i32.xor` respectively, and returning the final accumulator via `$make-fixnum-or-float`.

#### Scenario: $fold-bitwise-and handles an empty list
- **WHEN** `$fold-bitwise-and` is called with an empty args list
- **THEN** the result SHALL be the fixnum `-1`

#### Scenario: $fold-bitwise-or handles an empty list
- **WHEN** `$fold-bitwise-or` is called with an empty args list
- **THEN** the result SHALL be the fixnum `0`

#### Scenario: $fold-bitwise-xor iterates through multiple args
- **WHEN** `$fold-bitwise-xor` is called with a four-element args list `(1 2 4 8)`
- **THEN** the result SHALL be the fixnum `15`
