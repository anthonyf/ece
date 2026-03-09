## ADDED Requirements

### Requirement: save-image! serializes full system state
The `save-image!` primitive SHALL write the complete ECE system state to a file. The state includes: the global instruction source vector, the global label table, the global environment, and the compile-time macro table.

#### Scenario: Save image after compiling code
- **WHEN** `(save-image! "test.image")` is called after defining functions and variables
- **THEN** a file `test.image` SHALL be created containing all compiled state
- **AND** `save-image!` SHALL return `#t`

#### Scenario: Save image overwrites existing file
- **WHEN** `(save-image! "test.image")` is called and the file already exists
- **THEN** the file SHALL be overwritten with the current state

### Requirement: load-image! restores full system state
The `load-image!` primitive SHALL read an image file and replace all global state. After loading, the system SHALL behave identically to the state at save time.

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

### Requirement: image round-trip preserves all data types
Images SHALL correctly round-trip all ECE data types stored in the environment.

#### Scenario: Round-trip numbers
- **WHEN** an image is saved with integer and float bindings
- **AND** the image is loaded
- **THEN** all numeric values SHALL be preserved exactly

#### Scenario: Round-trip strings
- **WHEN** an image is saved with string bindings (including empty strings and strings with special characters)
- **AND** the image is loaded
- **THEN** all string values SHALL be preserved exactly

#### Scenario: Round-trip lists and nested structures
- **WHEN** an image is saved with list, vector, and hash table bindings
- **AND** the image is loaded
- **THEN** all compound values SHALL be preserved with correct structure

#### Scenario: Round-trip symbols and booleans
- **WHEN** an image is saved with symbol and boolean bindings
- **AND** the image is loaded
- **THEN** all symbols and booleans SHALL be preserved

### Requirement: image round-trip preserves prelude functions
After loading an image that was saved with the prelude compiled, all prelude functions SHALL work correctly.

#### Scenario: Prelude functions work after image load
- **WHEN** an image is saved after the prelude is loaded
- **AND** the image is loaded into a fresh runtime
- **THEN** `(map (lambda (x) (* x x)) (list 1 2 3))` SHALL return `(1 4 9)`
- **AND** `(filter odd? (list 1 2 3 4 5))` SHALL return `(1 3 5)`
- **AND** `(reduce + 0 (list 1 2 3))` SHALL return `6`

### Requirement: image handles continuations
Continuations captured before save SHALL be valid after load.

#### Scenario: Continuation survives image round-trip
- **WHEN** a continuation is captured with `call/cc` and stored in a variable
- **AND** the image is saved and loaded
- **THEN** invoking the restored continuation SHALL resume execution correctly

### Requirement: save-image! works from ECE code
The `save-image!` and `load-image!` primitives SHALL be callable from ECE source code.

#### Scenario: Primitives are bound in global environment
- **WHEN** the system is initialized
- **THEN** `save-image!` and `load-image!` SHALL be bound as primitives in the global environment
