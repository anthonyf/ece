## ADDED Requirements

### Requirement: save-image! serializes full system state
The `save-image!` primitive SHALL compact the instruction vector before serializing, removing unreachable instructions. It SHALL then write the compacted system state to a file. The compaction SHALL operate on copies — the live system state SHALL remain untouched.

The compaction algorithm SHALL:
1. Collect all entry PCs from compiled procedures in the global environment, macro table, and procedure-name table
2. Determine reachable entry PCs by walking all `(compiled-procedure pc env)` values in the global environment and macro table (transitively, including continuations)
3. Use sorted entry PCs as block boundaries — each procedure's instructions form a contiguous block from its entry PC to the next entry PC
4. Copy only blocks whose entry PC is reachable into a compacted instruction vector
5. Build an old-pc → new-pc remapping table
6. Deep-copy the global environment and macro table, remapping all PCs in compiled procedures and continuations
7. Remap the label table and procedure-name table using the same mapping
8. Serialize the compacted copies

#### Scenario: Save image after compiling code
- **WHEN** `(save-image! "test.image")` is called after defining functions and variables
- **THEN** a file `test.image` SHALL be created containing compacted state with no dead instructions
- **AND** `save-image!` SHALL return `#t`

#### Scenario: Save image overwrites existing file
- **WHEN** `(save-image! "test.image")` is called and the file already exists
- **THEN** the file SHALL be overwritten with the current compacted state

#### Scenario: Compaction removes dead code from redefinitions
- **WHEN** a function is defined, then redefined with a different body
- **AND** `(save-image! "test.image")` is called
- **THEN** the saved image SHALL contain only the instructions for the latest definition
- **AND** the saved instruction vector SHALL be smaller than the live instruction vector

#### Scenario: Compaction preserves live system state
- **WHEN** `(save-image! "test.image")` is called
- **THEN** the live instruction vector, environment, macro table, and label table SHALL be unchanged
- **AND** subsequent evaluation SHALL continue to work correctly using the original (uncompacted) state

#### Scenario: Anonymous lambdas are preserved
- **WHEN** a closure is created via `(lambda ...)` and stored in a variable
- **AND** `(save-image! "test.image")` is called
- **THEN** the saved image SHALL include the anonymous lambda's instructions
- **AND** invoking the restored closure after `load-image!` SHALL work correctly

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
