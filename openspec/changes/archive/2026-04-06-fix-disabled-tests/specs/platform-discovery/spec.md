## MODIFIED Requirements

### Requirement: platform-has? predicate

Accepts a symbol name and returns `#t` if the primitive is available on the current runtime, `#f` otherwise. On all platforms (CL and WASM), `platform-has?` MUST return ECE `#f` (not host-language falsy values like CL `nil`/`()`) for unknown or unavailable primitives.

#### Scenario: core primitive available
- **WHEN** `(platform-has? 'car)` is evaluated
- **THEN** the result is `#t`

#### Scenario: platform primitive available on its platform
- **WHEN** `(platform-has? '<platform-specific-name>)` is evaluated on that platform
- **THEN** the result is `#t`

#### Scenario: platform primitive unavailable on other platform
- **WHEN** `(platform-has? '<other-platform-name>)` is evaluated
- **THEN** the result is `#f`

#### Scenario: unknown name returns #f
- **WHEN** `(platform-has? 'nonexistent-primitive-xyz)` is evaluated
- **THEN** the result is exactly `#f` (not `()` or any other falsy value)
- **AND** `(eq? (platform-has? 'nonexistent-primitive-xyz) #f)` returns `#t`
