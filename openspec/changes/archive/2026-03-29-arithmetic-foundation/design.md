## Context

ECE's `modulo` (primitive ID 4) has divergent semantics across hosts. CL maps to `cl:mod` (floor remainder), WASM uses `i32.rem_s` (truncation remainder). For negative operands these produce different results: `(modulo -13 4)` → `3` on CL, `-1` on WASM. R7RS specifies floor semantics.

ECE also lacks standard R7RS integer arithmetic operations (`quotient`, `remainder`, `floor`, `truncate`, `ceiling`, `round`). These are needed for the Layer 2 kernel minimization effort, specifically for implementing `number->string` in ECE (digit extraction requires integer division).

Currently CL's `/` returns exact rationals (`7/2`) while WASM promotes to f64 (`3.5`). Both `floor` and `truncate` produce the same integer result from either representation, making ECE-derived operations portable across hosts.

## Goals / Non-Goals

**Goals:**
- Fix WASM modulo to match R7RS floor semantics
- Add all standard R7RS integer division and rounding operations
- Migrate `modulo` from host-implemented to ECE-derived
- Establish the pattern for Layer 2 primitive migration (add axioms, derive operations in ECE)

**Non-Goals:**
- Unifying CL rationals vs WASM floats (pre-existing divergence, separate concern)
- Migrating other primitives in this change (Batch 1a free wins are a separate change)
- Bignum support (fixnum range is within f64 precision)

## Decisions

### Decision 1: `truncate` and `floor` as the axioms, not `quotient`

**Choice**: Add `truncate` (toward zero) and `floor` (toward -∞) as core primitives, derive everything else.

**Alternatives considered**:
- *Add `quotient` and `remainder` directly*: Requires 2 core primitives but doesn't provide `floor`/`truncate` for general use, and doesn't fix `modulo` (still need floor semantics).
- *Derive `quotient` from `modulo`*: `modulo` uses floor semantics, `quotient` uses truncation — can't cleanly derive one from the other without both `floor` and `truncate`.
- *Add all 7 as core*: Maximizes host code, contradicts kernel minimization goal.

**Rationale**: `truncate` and `floor` are the two fundamental rounding modes. Every other operation is a one-liner derivation:
```
quotient  = truncate(a/b)
remainder = a - quotient(a,b) * b
modulo    = a - floor(a/b) * b
ceiling   = floor(x) + (1 if non-integer)
round     = floor-based with tie-breaking
```

Two axioms → five derived operations. Each axiom maps to a single host instruction (CL: `cl:truncate`/`cl:floor`, WASM: `f64.trunc`/`f64.floor`).

### Decision 2: Primitive IDs 108, 109

**Choice**: Use gap in the 100-range (108 for `truncate`, 109 for `floor`).

**Rationale**: IDs 108-111 are unassigned in primitives.def. These are in the extended range but still below 200 (browser). Arithmetic operations logically belong near the existing arithmetic primitives (0-4), but the 0-99 range is full. The manifest is ID-indexed, not range-restricted — any ID works for core.

### Decision 3: ECE `modulo` inserted before `even?` in prelude.scm

**Choice**: New "Integer arithmetic" section between "Core list functions" and "Derived predicates".

**Rationale**: `even?` (line 72) calls `modulo`. If ECE `modulo` is defined after `even?`, the compiler would bind `even?` to the host primitive. Defining `modulo` first ensures `even?` compiles against the ECE version. `ceiling` and `round` go after `even?` since `round` uses banker's rounding via `even?`.

### Decision 4: Two-pass bootstrap for migration

**Choice**: Standard two-pass pattern — (1) add ECE definitions with host still present, bootstrap, (2) remove host, bootstrap again.

**Rationale**: Old .ecec files may contain `(apply-primitive-procedure (primitive 4) ...)`. Pass 1 generates new .ecec files that call the compiled `modulo`. Pass 2 verifies the host primitive is no longer needed. This is the established pattern from previous migrations (char predicates, string ops, etc.).

### Decision 5: CL `truncate`/`floor` wrappers use `values`

**Choice**: Wrap CL's `truncate`/`floor` with `(values (cl:truncate x))` to discard the second return value.

**Rationale**: CL's `truncate` and `floor` return two values (quotient and remainder). ECE expects a single return value. Using `values` strips the second value.

## Risks / Trade-offs

**[Risk] Performance regression for `modulo`** → ECE `modulo` calls `/`, `floor`, `*`, `-` (4 operations) instead of a single host `mod` call. For hot paths like `even?`, this is ~4x more primitive calls. Mitigation: `even?` with `(modulo n 2)` where both arguments are small positive integers is already fast; the absolute overhead is negligible. If profiling shows a bottleneck, `modulo` can be restored as core without changing the ECE API.

**[Risk] Float precision for large numbers** → `(/ large-a large-b)` on WASM produces f64, which has 53-bit mantissa. Mitigation: WASM fixnums are 30-bit, well within f64 precision. Any fixnum division is exact in f64. This only matters if ECE later adds bignums.

**[Risk] CL rationals leak through ECE arithmetic** → `(/ 7 2)` on CL returns `7/2` (a ratio). `(floor 7/2)` works correctly, but rationals may surprise serialization or WASM-targeted code. Mitigation: Pre-existing issue, not introduced by this change. Documented as separate concern.

**[Risk] `round` banker's rounding edge case** → R7RS specifies ties round to even: `(round 0.5)` → `0`, `(round 1.5)` → `2`. The implementation uses `even?` which depends on `modulo`. Mitigation: Dependency chain is non-circular (`floor` → `modulo` → `even?` → `round`). Test suite covers tie-breaking.
