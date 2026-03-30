## MODIFIED Requirements

### Requirement: %raw-error implemented on WASM
Primitive 81 (`%raw-error`) SHALL be implemented on the WASM runtime. It SHALL signal a fatal error by calling `$signal-error-str` with the error message, which throws a JS exception via the `runtime_error` import.

#### Scenario: %raw-error signals fatal error
- **WHEN** `(%raw-error "something failed")` is evaluated on WASM
- **THEN** a JS exception SHALL be thrown with the message "something failed"

### Requirement: division-by-zero catchable by guard
`quotient`, `modulo`, and `remainder` SHALL check for zero divisor and call ECE's `error` function (not a WAT-level error). This makes the error catchable by `guard` on all platforms.

#### Scenario: guard catches division by zero in modulo
- **WHEN** `(guard (e ((error-object? e) #t)) (modulo 10 0) #f)` is evaluated on WASM
- **THEN** the result SHALL be `#t`

#### Scenario: guard catches division by zero in quotient
- **WHEN** `(guard (e ((error-object? e) #t)) (quotient 10 0) #f)` is evaluated on WASM
- **THEN** the result SHALL be `#t`
