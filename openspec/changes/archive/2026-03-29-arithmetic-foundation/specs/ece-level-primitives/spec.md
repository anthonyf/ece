## MODIFIED Requirements

### Requirement: primitives.def updated
Migrated primitives SHALL have their platform annotation changed from `core` to `ece` in `primitives.def` to document that they are now prelude-level. Additionally, new core primitives `truncate` (108) and `floor` (109) SHALL be added.

#### Scenario: annotation reflects migration
- **WHEN** `primitives.def` is read
- **THEN** `char-whitespace?` (47), `char-alphabetic?` (48), `char-numeric?` (49), `equal?` (21), `eqv?` (174), `gensym` (82), `string-downcase` (36), `string-upcase` (37), `string-split` (38), `string-trim` (39), `string-contains?` (40), `string-join` (41), `print` (66), and `modulo` (4) SHALL have platform `ece`

#### Scenario: new core primitives registered
- **WHEN** `primitives.def` is read
- **THEN** `truncate` (108) and `floor` (109) SHALL have platform `core`

### Requirement: both hosts remove migrated primitives
For each migrated primitive, the corresponding host dispatch entry SHALL be removed from both `runtime.lisp` (CL) and `runtime.wat` (WASM) after the ECE implementation is verified.

#### Scenario: modulo not in CL dispatch
- **WHEN** the CL primitive dispatch table is built
- **THEN** ID 4 (`modulo`) SHALL NOT have a host-level handler (the ECE prelude provides the implementation)

#### Scenario: modulo not in WASM dispatch
- **WHEN** the WASM `apply-primitive` function receives primitive ID 4
- **THEN** it SHALL NOT have a host-level handler (the ECE prelude provides the implementation)
