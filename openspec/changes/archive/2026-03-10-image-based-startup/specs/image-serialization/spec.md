## MODIFIED Requirements

### Requirement: save-image! serializes full system state
The `save-image!` primitive SHALL write the complete ECE system state to a file. The state includes: the global instruction source vector, the global label table, the global environment, the compile-time macro table, the procedure name table, the parameter table, and the parameter counter.

#### Scenario: Save image after compiling code
- **WHEN** `(save-image! "test.image")` is called after defining functions and variables
- **THEN** a file `test.image` SHALL be created containing all compiled state including procedure names
- **AND** `save-image!` SHALL return `#t`

#### Scenario: Save image overwrites existing file
- **WHEN** `(save-image! "test.image")` is called and the file already exists
- **THEN** the file SHALL be overwritten with the current state

### Requirement: load-image! restores full system state
The `load-image!` primitive SHALL read an image file and replace all global state. After loading, the system SHALL behave identically to the state at save time, including procedure name mappings and parameter objects.

#### Scenario: Load image restores definitions
- **WHEN** an image is saved after `(define x 42)` and `(define (square n) (* n n))`
- **AND** `load-image!` is called in a fresh runtime
- **THEN** `x` SHALL evaluate to `42`
- **AND** `(square 5)` SHALL evaluate to `25`

#### Scenario: Load image restores compiled procedures
- **WHEN** an image is saved after compiling lambda expressions and closures
- **AND** the image is loaded
- **THEN** all compiled procedures SHALL execute correctly with proper environments

#### Scenario: Load image restores compile-time macros
- **WHEN** an image is saved after `(define-macro (my-macro x) ...)`
- **AND** the image is loaded
- **THEN** subsequent compilation SHALL expand `my-macro` correctly

#### Scenario: Load image re-resolves operations
- **WHEN** an image is loaded from disk
- **THEN** all `(op name)` forms in the instruction vector SHALL be resolved to function pointers
- **AND** execution performance SHALL be identical to pre-save performance

#### Scenario: Load image restores procedure names
- **WHEN** an image is saved after `(define (f x) (+ x 1))`
- **AND** the image is loaded
- **THEN** the procedure name table SHALL map `f`'s entry PC to the symbol `f`

#### Scenario: Load image restores parameter objects
- **WHEN** an image is saved with parameter objects (e.g., `*mc-compile-lexical-env*`, `current-input-port`)
- **AND** the image is loaded
- **THEN** all parameter objects SHALL be functional (get and set operations work)
- **AND** `parameterize` SHALL work correctly with restored parameters
