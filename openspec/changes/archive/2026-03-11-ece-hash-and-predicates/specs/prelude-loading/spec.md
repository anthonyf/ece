## MODIFIED Requirements

### Requirement: Definition order preserves dependencies
`prelude.scm` SHALL define functions in dependency order. List accessors and core list functions SHALL appear first (before `map`/`filter`), followed by derived predicates, math helpers, hash table operations, then higher-order functions and macros.

#### Scenario: Prelude defines all stdlib forms
- **WHEN** the system is loaded and the REPL starts
- **THEN** all stdlib functions and macros SHALL be available including the newly ECE-defined: `cadr`, `caddr`, `caar`, `cddr`, `list-ref`, `list-tail`, `reverse`, `length`, `append`, `member`, `assoc`, `not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, `>=`, `abs`, `min`, `max`, `hash-table`, `hash-table?`, `hash-ref`, `hash-set!`, `hash-set`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-remove!`

#### Scenario: Definition order preserves dependencies
- **WHEN** `prelude.scm` is loaded
- **THEN** definitions SHALL appear in dependency order: list accessors first, then core list functions, then predicates, then map/reduce/filter, then math helpers, then hash table ops (before define-record), then macros
