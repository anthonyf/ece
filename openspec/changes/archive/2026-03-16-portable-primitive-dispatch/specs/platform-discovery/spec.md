## ADDED Requirements

### Requirement: platform-has? predicate
`platform-has?` SHALL accept a symbol name and return `#t` if the named primitive is available on the current runtime, `#f` otherwise.

#### Scenario: core primitive available
- **WHEN** `(platform-has? '+)` is evaluated
- **THEN** the result SHALL be `#t`

#### Scenario: platform primitive available on its platform
- **WHEN** `(platform-has? 'open-input-file)` is evaluated on the CL runtime
- **THEN** the result SHALL be `#t`

#### Scenario: platform primitive unavailable on other platform
- **WHEN** `(platform-has? '%create-element)` is evaluated on the CL runtime
- **THEN** the result SHALL be `#f`

#### Scenario: unknown name
- **WHEN** `(platform-has? 'nonexistent-primitive)` is evaluated
- **THEN** the result SHALL be `#f`

### Requirement: %platform-primitives list
`%platform-primitives` SHALL return a list of all primitive names available on the current runtime.

#### Scenario: core primitives included
- **WHEN** `(%platform-primitives)` is evaluated on any runtime
- **THEN** the result SHALL include `+`, `-`, `car`, `cdr`, `cons`, `display`, and all other core primitives

#### Scenario: platform primitives included
- **WHEN** `(%platform-primitives)` is evaluated on the CL runtime
- **THEN** the result SHALL include `open-input-file` and other CL platform primitives

#### Scenario: other platform primitives excluded
- **WHEN** `(%platform-primitives)` is evaluated on the CL runtime
- **THEN** the result SHALL NOT include `%create-element` or other browser-only primitives

### Requirement: discovery primitives are themselves core
Both `platform-has?` and `%platform-primitives` SHALL be listed in the manifest as `core` primitives, available on all runtimes.
