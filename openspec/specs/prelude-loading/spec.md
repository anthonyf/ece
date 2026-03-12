## ADDED Requirements

### Requirement: Prelude file contains all pure-ECE stdlib definitions
`src/prelude.scm` SHALL contain every definition currently implemented as `(evaluate '...)` calls in `ece.lisp`, written as native ECE source (no CL wrappers). `prelude.scm` SHALL define functions in dependency order. List accessors and core list functions SHALL appear first (before `map`/`filter`), followed by derived predicates, math helpers, hash table operations, then higher-order functions and macros.

#### Scenario: Prelude defines all stdlib forms
- **WHEN** the system is loaded and the REPL starts
- **THEN** all stdlib functions and macros SHALL be available including the newly ECE-defined: `cadr`, `caddr`, `caar`, `cddr`, `list-ref`, `list-tail`, `reverse`, `length`, `append`, `member`, `assoc`, `not`, `zero?`, `even?`, `odd?`, `positive?`, `negative?`, `<=`, `>=`, `abs`, `min`, `max`, `hash-table`, `hash-table?`, `hash-ref`, `hash-set!`, `hash-set`, `hash-has-key?`, `hash-keys`, `hash-values`, `hash-count`, `hash-remove!`

#### Scenario: Definition order preserves dependencies
- **WHEN** `prelude.scm` is loaded
- **THEN** definitions SHALL appear in dependency order: list accessors first, then core list functions, then predicates, then map/reduce/filter, then math helpers, then hash table ops (before define-record), then macros

### Requirement: Prelude is loaded automatically at system initialization
The evaluator SHALL load `src/prelude.scm` automatically via `ece-load` during system initialization, after the evaluator is defined and before the REPL is available.

#### Scenario: Automatic loading via ASDF path resolution
- **WHEN** the ECE system is loaded via ASDF
- **THEN** `ece-load` SHALL be called with `(asdf:system-relative-pathname :ece "src/prelude.scm")` to load the prelude

#### Scenario: Prelude loads without CL readtable dance
- **WHEN** the prelude is loaded
- **THEN** no explicit `*readtable*` switching SHALL be needed in `ece.lisp` because `ece-load` handles readtable binding internally

### Requirement: Inline evaluate calls are removed from ece.lisp
All `(evaluate '...)` stdlib calls and the surrounding CL readtable switches SHALL be removed from `ece.lisp`.

#### Scenario: No evaluate wrappers remain for stdlib
- **WHEN** the prelude extraction is complete
- **THEN** `ece.lisp` SHALL contain no `(evaluate '(define ...))` or `(evaluate '(define-macro ...))` calls for stdlib definitions

#### Scenario: Readtable switch block is removed
- **WHEN** the prelude extraction is complete
- **THEN** the `(setf *readtable* *ece-readtable*)` / `(setf *readtable* (copy-readtable nil))` sandwich around stdlib definitions SHALL be removed from `ece.lisp`

### Requirement: Prelude is registered as ASDF static-file
`prelude.scm` SHALL be registered as a `:static-file` component in the ASDF system definition so it is included in system distribution.

#### Scenario: ASDF knows about prelude.scm
- **WHEN** the ASDF system definition is inspected
- **THEN** `prelude.scm` SHALL appear as a `:static-file` component

### Requirement: Behavior is identical after extraction
The extraction SHALL produce no behavioral changes — the same functions, macros, and values SHALL be available at startup as before.

#### Scenario: All existing tests pass unchanged
- **WHEN** the test suite is run after the extraction
- **THEN** all existing tests SHALL pass without modification
