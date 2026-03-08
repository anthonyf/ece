## Context

`ece-string->number` uses `read-from-string` wrapped in `handler-case`. This invokes the full CL reader, which can trigger readtable macros, parse CL-specific number syntax (ratios, complex numbers), and potentially execute reader macros like `#.`.

## Goals / Non-Goals

**Goals:**
- Safe number parsing that never invokes the CL reader
- Support integers (positive, negative) and floating-point decimals
- Return `nil` for anything that isn't a simple number

**Non-Goals:**
- Scientific notation (e.g., `1e10`)
- Radix prefixes (e.g., `#x1F`)
- Exact/inexact distinction

## Decisions

### Use parse-integer for integers, manual parse for floats
CL's `parse-integer` with `:junk-allowed t` safely parses integers without the reader. For floats, split on `.` and combine the integer and fractional parts. This avoids needing any external dependency.

### Reject CL-specific number syntax
Ratios (`3/4`), complex numbers (`#C(1 2)`), and any reader macro syntax return `nil`. Only plain integers and decimal floats are valid.

## Risks / Trade-offs

- No scientific notation support — acceptable for ECE's use cases. Can be added later if needed.
