## MODIFIED Requirements

### Requirement: save-continuation! writes value to file
`save-continuation!` SHALL serialize any ECE value to a file using the value-serialization format.

#### Scenario: Save plain value
- **WHEN** `(save-continuation! "state.dat" (list 1 2 3))` is called
- **THEN** the file SHALL be created with the serialized s-expression
- **AND** the return value SHALL be `#t`

#### Scenario: Save continuation
- **WHEN** `(save-continuation! "state.dat" k)` is called where `k` is a captured continuation
- **THEN** the file SHALL contain the serialized continuation with stack and space-qualified addresses

### Requirement: load-continuation reads value from file
`load-continuation` SHALL deserialize an ECE value from a file written by `save-continuation!`.

#### Scenario: Load plain value
- **WHEN** `(load-continuation "state.dat")` is called on a file written by `save-continuation!`
- **THEN** the returned value SHALL be `equal?` to the original saved value

#### Scenario: Load and invoke continuation
- **GIVEN** a continuation `k` was saved with `save-continuation!`
- **WHEN** `(load-continuation "state.dat")` is called
- **THEN** the returned continuation SHALL be invokable with the same behavior as the original
