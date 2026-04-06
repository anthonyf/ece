## ADDED Requirements

### Requirement: keyword? recognizes ECE keywords

`keyword?` SHALL return `#t` for ECE keyword symbols — symbols whose name starts with `":"` (e.g., the symbol created by the ECE reader for `:foo`). It MUST NOT rely on CL's `keywordp` since ECE keywords are regular symbols in the ECE package, not CL keyword package members.

#### Scenario: keyword? on ECE keyword
- **WHEN** `(keyword? :foo)` is evaluated
- **THEN** the result is `#t`

#### Scenario: keyword? on non-keyword symbol
- **WHEN** `(keyword? 'hello)` is evaluated
- **THEN** the result is `#f`

#### Scenario: keyword? on non-symbol
- **WHEN** `(keyword? 42)` is evaluated
- **THEN** the result is `#f`
