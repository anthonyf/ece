## ADDED Requirements

### Requirement: save-continuation! writes a value to a file
The `save-continuation!` function SHALL accept a filename and a value, and write the value to the file as a readable s-expression. It SHALL use `*print-circle*` to handle shared structure. It SHALL overwrite the file if it already exists. It SHALL return `t` on success.

#### Scenario: Save a continuation
- **WHEN** `(save-continuation! "test.sav" k)` is evaluated where `k` is a captured continuation
- **THEN** the continuation SHALL be written to `test.sav` as a readable s-expression and the function SHALL return `t`

#### Scenario: Save a plain value
- **WHEN** `(save-continuation! "test.sav" (list 1 2 3))` is evaluated
- **THEN** the list `(1 2 3)` SHALL be written to `test.sav`

#### Scenario: Overwrite existing file
- **WHEN** `(save-continuation! "test.sav" "new")` is evaluated and `test.sav` already exists
- **THEN** the file SHALL be overwritten with the new value

### Requirement: load-continuation reads a value from a file
The `load-continuation` function SHALL accept a filename and read a single s-expression from the file, returning it as an ECE value. It SHALL use the ECE readtable so hash table literals and quasiquote syntax are restored. Symbols SHALL resolve in the ECE package.

#### Scenario: Load a saved continuation
- **WHEN** a continuation was saved with `save-continuation!` and `(load-continuation "test.sav")` is evaluated
- **THEN** it SHALL return a continuation value that can be invoked to resume execution

#### Scenario: Load a plain value
- **WHEN** `(list 1 2 3)` was saved and `(load-continuation "test.sav")` is evaluated
- **THEN** it SHALL return `(1 2 3)`

#### Scenario: Round-trip with hash tables
- **WHEN** a hash table value is saved with `save-continuation!` and loaded with `load-continuation`
- **THEN** the loaded value SHALL be `equal?` to the original
