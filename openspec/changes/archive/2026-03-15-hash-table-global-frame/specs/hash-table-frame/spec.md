## ADDED Requirements

### Requirement: hash-table-backed environment frame
The system SHALL support a hash-table-backed environment frame type represented as `(:hash-frame . <hash-table>)`. This frame type SHALL provide O(1) variable lookup, set, and define operations. It SHALL be used for the global environment frame.

#### Scenario: Global environment uses hash-table frame
- **WHEN** the ECE system is initialized
- **THEN** `*global-env*` SHALL contain a single hash-table frame with all primitive bindings
- **AND** the frame SHALL be a cons cell with `car` equal to `:hash-frame`

#### Scenario: Hash-table frame after image load
- **WHEN** a binary image is loaded
- **THEN** the global environment SHALL be restored with a hash-table frame
- **AND** all variable lookups SHALL use O(1) hash-table access

### Requirement: lookup-variable-value dispatches on frame type
The `lookup-variable-value` function SHALL check each frame's type and use the appropriate lookup strategy: hash-table gethash for hash-table frames, vector skip for vector frames, linear scan for list frames.

#### Scenario: Lookup in hash-table frame
- **WHEN** `lookup-variable-value` is called for a variable bound in a hash-table frame
- **THEN** it SHALL return the value via hash-table lookup in O(1) time

#### Scenario: Lookup falls through hash-table frame
- **WHEN** `lookup-variable-value` is called for a variable NOT in the hash-table frame
- **THEN** it SHALL continue searching subsequent frames in the environment

#### Scenario: Lookup with mixed frame types
- **WHEN** an environment contains vector frames, list frames, and a hash-table frame
- **THEN** `lookup-variable-value` SHALL correctly search through all frame types

### Requirement: set-variable-value! dispatches on frame type
The `set-variable-value!` function SHALL support hash-table frames, updating the value via `(setf gethash)`.

#### Scenario: Set in hash-table frame
- **WHEN** `set-variable-value!` is called for a variable in a hash-table frame
- **THEN** it SHALL update the value in the hash-table

### Requirement: define-variable! dispatches on frame type
The `define-variable!` function SHALL support hash-table frames, inserting or updating via `(setf gethash)`.

#### Scenario: Define new variable in hash-table frame
- **WHEN** `define-variable!` is called with a variable not yet in the hash-table frame
- **THEN** it SHALL add the binding to the hash-table

#### Scenario: Redefine existing variable in hash-table frame
- **WHEN** `define-variable!` is called with a variable already in the hash-table frame
- **THEN** it SHALL update the existing binding

### Requirement: ECE-side hash-frame primitives
The CL runtime SHALL expose primitives for ECE code to work with hash-table frames: `%hash-frame?`, `%hash-frame-entries`, `%make-hash-frame`, `%hash-frame-set!`.

#### Scenario: Detect hash-table frame from ECE
- **WHEN** ECE code calls `(%hash-frame? frame)` on a hash-table frame
- **THEN** it SHALL return `#t`
- **WHEN** called on a list or vector frame
- **THEN** it SHALL return `#f`

#### Scenario: Get entries from hash-table frame
- **WHEN** ECE code calls `(%hash-frame-entries frame)`
- **THEN** it SHALL return an alist of `(symbol . value)` pairs

#### Scenario: Create and populate hash-table frame
- **WHEN** ECE code calls `(%make-hash-frame)` and then `(%hash-frame-set! frame key val)`
- **THEN** subsequent `(%hash-frame-entries frame)` SHALL include the binding
