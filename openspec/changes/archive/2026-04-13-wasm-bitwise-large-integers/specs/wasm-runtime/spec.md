## MODIFIED Requirements

### Requirement: WASM bitwise primitives handle any representable integer, not just fixnums
The WASM implementations of `bitwise-and` (76), `bitwise-or` (77), `bitwise-xor` (78), `bitwise-not` (79), and `arithmetic-shift` (80) SHALL accept ECE integer arguments in any representation (fixnum or float-box) over the full `[-2^31, 2^32-1]` bit-pattern range, compute their result in 32-bit space, and return an ECE integer in whichever representation fits the result (fixnum when the 32-bit result is in `[-2^29, 2^29-1]`, float-box otherwise).

For inputs in `[2^31, 2^32-1]` (unsigned-valued 32-bit words, as produced by SHA-1 and similar algorithms), the WASM runtime treats them as signed i32 values with the same bit pattern. Subsequent operations that are themselves bit-pattern-preserving (`+`, `-`, bitwise ops, shifts, byte-wise masking) continue to give the same low-32-bit result as the CL runtime's bignum interpretation. Direct numerical comparison between the two runtimes for values whose result has bit 31 set is not guaranteed, but byte-level outputs (via `(bitwise-and x 255)` and similar) are.

#### Scenario: Both inputs are fixnums and result fits in fixnum range
- **WHEN** `(bitwise-or 3 5)` is evaluated on the WASM runtime
- **THEN** the result SHALL equal the ECE integer `7`
- **AND** the result SHALL be a fixnum (`i31ref`)

#### Scenario: Large-positive unsigned-coded input survives via trunc-wrap
- **WHEN** `(bitwise-and 4023233417 255)` is evaluated on the WASM runtime
- **AND** `4023233417` is `0xEFCDAB89`, stored as an f64 float-box
- **THEN** the result SHALL equal `137` (= `0x89`), matching the low byte of the input
- **AND** the read of the float-box SHALL NOT trap via `ref.cast (ref i31)`

#### Scenario: Both inputs are float-boxes above signed i32 range
- **WHEN** `(bitwise-xor 1518500249 1859775393)` is evaluated on the WASM runtime
- **THEN** the computation SHALL succeed without a cast trap
- **AND** the byte-extracted output (`bitwise-and` with `255`, or shifted-and-masked) SHALL match the CL runtime's result

#### Scenario: `arithmetic-shift` left overflows fixnum range
- **WHEN** `(arithmetic-shift 97 24)` is evaluated on the WASM runtime
- **AND** the result is `1627389952 = 0x61000000`, which exceeds the fixnum range
- **THEN** the result SHALL be an ECE integer equal to `1627389952`
- **AND** it SHALL NOT be truncated to a smaller value by `$make-fixnum`

#### Scenario: `arithmetic-shift` by 32 or more clamps correctly
- **WHEN** `(arithmetic-shift 24 -32)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `0` (the non-negative input shifted past all its bits)
- **AND** WASM's native 5-bit shift-count masking SHALL NOT cause the value to be returned unchanged

#### Scenario: `arithmetic-shift` right by 32+ on a negative value sign-extends
- **WHEN** `(arithmetic-shift -1 -32)` is evaluated on the WASM runtime
- **THEN** the result SHALL be `-1` (sign bit extends through the full width)

#### Scenario: `bitwise-not` of a large integer
- **WHEN** `(bitwise-not 0)` is evaluated on the WASM runtime
- **THEN** the result SHALL equal `-1`
- **WHEN** `(bitwise-not 3285377520)` is evaluated (`0xC3D2E1F0`, a float-box)
- **THEN** the read SHALL NOT trap
- **AND** the result's low-byte extraction SHALL match the CL runtime's byte-level output

### Requirement: WASM ecec reader accepts large integer literals
The WASM runtime's `.ecec` parser SHALL accept integer literals across the full exactly-representable f64 range (up to 2^53), storing values outside the fixnum range as f64 float-boxes. Previously the parser accumulated into an i32 and unconditionally called `$make-fixnum`, corrupting any literal above the fixnum-encoding range and overflowing on literals above 2^31. SHA-1 round constants such as `4023233417` (`0xEFCDAB89`) are literal integers in `tests/ece/common/test-sha1.scm` and `src/sha1.scm`; they SHALL round-trip through the reader without loss.

#### Scenario: Literal in `[2^29, 2^31-1]` stored as float-box
- **WHEN** the `.ecec` parser encounters the literal `1073741823`
- **THEN** the value SHALL be routed through `$f64-to-ece-number`
- **AND** the result SHALL be a float-box holding `1073741823.0` (not a corrupted fixnum)

#### Scenario: Literal above 2^31 survives parsing
- **WHEN** the `.ecec` parser encounters the literal `4023233417`
- **THEN** the parser SHALL NOT trap from i32 overflow
- **AND** the resulting value SHALL be a float-box holding exactly `4023233417.0`

### Requirement: WASM `write` / `number->string` of float-box integers is exact
`$prim-number-to-string` SHALL print any integer-valued number — fixnum or float-box — using its exact decimal representation. Previously the float-box path routed through `$make-fixnum` to re-use the fixnum digit loop, silently corrupting any value outside the fixnum encoding range. The digit loop SHALL use an i64 accumulator so any f64-exact integer (up to 2^53) prints correctly.

Additionally, `$write-to-string-impl` SHALL handle float-box values directly (previously it fell through to the `#?` fallback string for any non-fixnum number).

#### Scenario: Print of a large-positive float-box
- **WHEN** `(write 1518500249)` is evaluated on the WASM runtime
- **THEN** the output SHALL be the string `"1518500249"`

#### Scenario: Print of a large-negative float-box
- **WHEN** `(write -1500216678)` is evaluated on the WASM runtime
- **THEN** the output SHALL be the string `"-1500216678"`

### Requirement: `$make-fixnum-or-float` helper exists and promotes on overflow
A helper function `$make-fixnum-or-float` SHALL exist in `wasm/runtime.wat` with signature `(param $n i32) (result (ref null eq))`. It SHALL return a fixnum (via `$make-fixnum`) when `$n` is in `[-2^29, 2^29-1]`, and a float-box (wrapping `f64.convert_i32_s $n`) otherwise. This helper is the single place where the fixnum overflow decision is made for i32 outputs of the bitwise primitives.

#### Scenario: Small positive input
- **WHEN** `$make-fixnum-or-float` is called with `$n = 5`
- **THEN** the result SHALL be a fixnum representing the integer `5`

#### Scenario: Large positive input
- **WHEN** `$make-fixnum-or-float` is called with `$n = 536870912` (2^29, one past the fixnum range)
- **THEN** the result SHALL be a float-box representing the integer `536870912`

#### Scenario: Large negative input
- **WHEN** `$make-fixnum-or-float` is called with `$n = -536870913` (-2^29 - 1, one past the fixnum range on the negative side)
- **THEN** the result SHALL be a float-box representing the integer `-536870913`

### Requirement: `$trunc-to-i32-wrap` helper wraps without trapping
A helper function `$trunc-to-i32-wrap` SHALL exist with signature `(param $n f64) (result i32)`. It takes an f64 (assumed to be an integer) and returns the i32 whose bit pattern matches the low 32 bits of the integer, without trapping on values outside signed i32 range. The implementation goes via `i64.trunc_f64_s` + `i32.wrap_i64`, which accepts any f64 integer up to 2^63 — comfortably above the 32-bit range ECE cares about for bitwise ops.

#### Scenario: Value above 2^31-1
- **WHEN** `$trunc-to-i32-wrap` is called with `4023233417.0`
- **THEN** the result SHALL be the i32 `-271733879` (bit pattern `0xEFCDAB89`)

### Requirement: `$arith-shift-i32` helper clamps shift counts
A helper function `$arith-shift-i32` SHALL exist with signature `(param $val i32) (param $count i32) (result i32)`. For shift counts in `[-31, 31]` it behaves as the native `i32.shl` / `i32.shr_s`. For counts `>= 32` the left-shift result SHALL be `0` (all bits shifted out). For counts `<= -32` the right-shift SHALL be `i32.shr_s val 31` (0 for non-negative inputs, -1 for negative inputs). This compensates for WASM's native masking of shift counts to the low 5 bits, which would otherwise make `(arithmetic-shift x -32)` a no-op.

#### Scenario: Right shift by 32 zeroes a non-negative input
- **WHEN** `$arith-shift-i32` is called with `val = 24`, `count = -32`
- **THEN** the result SHALL be `0`

#### Scenario: Left shift by 32 zeroes the result
- **WHEN** `$arith-shift-i32` is called with `val = 42`, `count = 32`
- **THEN** the result SHALL be `0`

#### Scenario: Right shift by 64 on a negative value
- **WHEN** `$arith-shift-i32` is called with `val = -1`, `count = -64`
- **THEN** the result SHALL be `-1` (sign bit extended all the way)
