## ADDED Requirements

### Requirement: sin primitive
The `sin` primitive (ID 152) SHALL accept one numeric argument in radians and return the sine as a float.

#### Scenario: sin of zero
- **WHEN** `(sin 0)` is called
- **THEN** the result SHALL be `0.0`

#### Scenario: sin of fixnum
- **WHEN** `(sin 1)` is called with a fixnum argument
- **THEN** the result SHALL be the float sine of 1 radian

### Requirement: cos primitive
The `cos` primitive (ID 153) SHALL accept one numeric argument in radians and return the cosine as a float.

#### Scenario: cos of zero
- **WHEN** `(cos 0)` is called
- **THEN** the result SHALL be `1.0`
