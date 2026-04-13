## MODIFIED Requirements

### Requirement: WASM bitwise primitives handle any representable integer, not just fixnums
The WASM implementations of `bitwise-or` (primitive 77), `bitwise-xor` (primitive 78), `bitwise-not` (primitive 79), and `arithmetic-shift` (primitive 80) SHALL accept ECE integer arguments in any representation (fixnum or float-box), compute their result in 32-bit signed-integer space, and return an ECE integer in whichever representation fits the result (fixnum if the result is in `[-2^30, 2^30-1]`, float-box otherwise). This brings them into consistency with `bitwise-and` (primitive 76), which already handles both representations.

#### Scenario: Both inputs are fixnums and result fits in fixnum range
- **WHEN** `(bitwise-or 3 5)` is evaluated on the WASM runtime
- **THEN** the result SHALL equal the ECE integer `7`
- **AND** the result SHALL be a fixnum (`i31ref`)

#### Scenario: Both inputs are fixnums but result overflows fixnum range
- **WHEN** `(bitwise-or 1073741823 1073741824)` is evaluated on the WASM runtime
- **AND** the two inputs are `2^30 - 1` (max fixnum) and `2^30` (smallest float-box)
- **THEN** the result SHALL equal the ECE integer `2147483647` (or the correct 32-bit-signed bitwise-or of the two)
- **AND** the result SHALL NOT be silently truncated to a smaller value

#### Scenario: One input is a float-box
- **WHEN** `(bitwise-or 1518500249 0)` is evaluated on the WASM runtime
- **AND** `1518500249` is `0x5A827999` (a value above the fixnum range, stored as float-box)
- **THEN** the `ref.cast (ref i31)` SHALL NOT trap
- **AND** the result SHALL equal `1518500249` (integer)

#### Scenario: Both inputs are float-boxes
- **WHEN** `(bitwise-xor 1518500249 1859775393)` is evaluated on the WASM runtime
- **THEN** the computation SHALL succeed without a cast trap
- **AND** the result SHALL equal the correct 32-bit bitwise-xor of the two values (matches CL runtime output byte-for-byte)

#### Scenario: `arithmetic-shift` left overflows fixnum range
- **WHEN** `(arithmetic-shift 97 24)` is evaluated on the WASM runtime
- **AND** the result is `1627389952 = 0x61000000`, which exceeds the fixnum range
- **THEN** the result SHALL be an ECE integer equal to `1627389952`
- **AND** it SHALL NOT be truncated to a smaller value by `$make-fixnum`

#### Scenario: `bitwise-not` of a large integer
- **WHEN** `(bitwise-not 0)` is evaluated on the WASM runtime
- **THEN** the result SHALL equal `-1`
- **WHEN** `(bitwise-not 3285377520)` is evaluated (0xC3D2E1F0, a float-box)
- **THEN** the `ref.cast (ref i31)` SHALL NOT trap
- **AND** the result SHALL be the correct 32-bit bitwise-not value

### Requirement: Cross-runtime equivalence for 32-bit bitwise operations
For any ECE integer inputs in the range `[-2^31, 2^31-1]`, the WASM runtime's `bitwise-or`, `bitwise-xor`, `bitwise-not`, `bitwise-and`, and `arithmetic-shift` primitives SHALL produce the same result as the CL runtime's implementations of those same primitives. This is a correctness requirement enforced by cross-runtime regression tests.

#### Scenario: Randomized cross-runtime comparison
- **WHEN** the test suite generates N random integer pairs with both inputs in `[-2^31, 2^31-1]`
- **AND** computes each of the five bitwise primitives on the same pair under both runtimes
- **THEN** the results SHALL be equal for every pair and every primitive

#### Scenario: SHA-1 test vectors pass on WASM
- **WHEN** `src/sha1.scm` is loaded into the WASM runtime after this change
- **AND** the RFC 3174 SHA-1 test vectors from `tests/ece/common/test-sha1.scm` run
- **THEN** all digests SHALL match the expected values from RFC 3174 byte-for-byte
- **AND** no test SHALL be skipped or gated to the CL runtime

### Requirement: `$make-fixnum-or-float` helper exists and promotes on overflow
A helper function `$make-fixnum-or-float` SHALL exist in `wasm/runtime.wat` with signature `(param $n i32) (result (ref null eq))`. It SHALL return a fixnum (via `$make-fixnum`) when `$n` is in `[-2^30, 2^30-1]`, and a float-box (wrapping `f64.convert_i32_s $n`) otherwise. This helper SHALL be the single place where the 30-bit fixnum overflow decision is made for i32 outputs of the bitwise primitives.

#### Scenario: Small positive input
- **WHEN** `$make-fixnum-or-float` is called with `$n = 5`
- **THEN** the result SHALL be a fixnum representing the integer `5`

#### Scenario: Large positive input
- **WHEN** `$make-fixnum-or-float` is called with `$n = 1073741824` (2^30, one past the fixnum range)
- **THEN** the result SHALL be a float-box representing the integer `1073741824`

#### Scenario: Large negative input
- **WHEN** `$make-fixnum-or-float` is called with `$n = -1073741825` (-2^30 - 1, one past the fixnum range on the negative side)
- **THEN** the result SHALL be a float-box representing the integer `-1073741825`

#### Scenario: Exact boundary (positive edge)
- **WHEN** `$make-fixnum-or-float` is called with `$n = 1073741823` (2^30 - 1, max fixnum)
- **THEN** the result SHALL be a fixnum
