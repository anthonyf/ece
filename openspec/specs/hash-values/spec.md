## ADDED Requirements

### Requirement: hash-values returns list of values
`hash-values` SHALL accept a hash table and return a list of all values in the table.

#### Scenario: Table with entries
- **WHEN** `(hash-values {name "Alice" age 30})` is evaluated
- **THEN** the result SHALL contain `"Alice"` and `30`

#### Scenario: Empty table
- **WHEN** `(hash-values (hash-table))` is evaluated
- **THEN** the result SHALL be `()`
