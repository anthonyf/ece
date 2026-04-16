## ADDED Requirements

### Requirement: %global-env-symbols returns all bound symbol names

ECE SHALL provide a `%global-env-symbols` host primitive that enumerates all bound names in `*global-env*`'s hash-frame and returns them as a list of strings.

#### Scenario: Returns a list of strings

- **WHEN** `(%global-env-symbols)` is called
- **THEN** it SHALL return a list
- **AND** every element of the list SHALL be a string

#### Scenario: Includes known builtins

- **WHEN** `(%global-env-symbols)` is called after bootstrap
- **THEN** the returned list SHALL include `"map"`, `"+"`, `"define"`, `"lambda"`, `"car"`, `"cdr"` among others

#### Scenario: Includes user-defined globals

- **WHEN** user defines `(define my-test-symbol-xyz 42)` at the REPL and then calls `(%global-env-symbols)`
- **THEN** the returned list SHALL include `"my-test-symbol-xyz"`

#### Scenario: Returns empty for no bindings

- **WHEN** `(%global-env-symbols)` is called on a hypothetical empty global environment
- **THEN** it SHALL return the empty list `()`
