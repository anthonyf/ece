## MODIFIED Requirements

### Requirement: make-parameter applies converter at creation time
When `make-parameter` is called with a converter function, the converter SHALL be applied to the initial value before storing it in the parameter.

#### Scenario: make-parameter with string-length converter
- **WHEN** `(make-parameter "hello" string-length)` is called
- **THEN** the parameter's value SHALL be `5`

#### Scenario: make-parameter without converter unchanged
- **WHEN** `(make-parameter 42)` is called
- **THEN** the parameter's value SHALL be `42`
