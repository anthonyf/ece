## ADDED Requirements

### Requirement: .ecec file contains a single flat instruction list
A .ecec file SHALL contain exactly two s-expressions: an ecec-header followed by a single instruction list containing all instructions for the file.

#### Scenario: Simple file with two top-level forms
- **WHEN** a .scm file containing `(define x 42)` and `(display x)` is compiled
- **THEN** the .ecec output SHALL contain one ecec-header and one instruction list that includes the instructions for both forms with an explicit env-reset between them

#### Scenario: Header format unchanged
- **WHEN** a .scm file is compiled
- **THEN** the ecec-header SHALL have the same format as before: `(ecec-header (space <name>) (macros (<list>)))`

### Requirement: Explicit env-reset between top-level expressions
The flat instruction list SHALL contain explicit `(assign env (const *global-env*))` instructions between the instruction sequences of adjacent top-level expressions.

#### Scenario: Boundary between two definitions
- **WHEN** a file defines `(define x 1)` followed by `(define y 2)`
- **THEN** the flat instruction list SHALL contain the instructions for the first define, then `(assign env (const *global-env*))`, then the instructions for the second define

### Requirement: One instruction per line formatting
Each instruction in the flat .ecec output SHALL be written on its own line within the outer parentheses. Labels SHALL appear on their own line.

#### Scenario: Pretty-printed output
- **WHEN** a .ecec file is written
- **THEN** the opening `(` appears on line 2 (after the header), each instruction and label appears on a subsequent line, and the closing `)` appears on its own line

#### Scenario: Git diff of compiler change
- **WHEN** a compiler modification changes one instruction in a compiled file
- **THEN** `git diff` SHALL show only the changed line(s), not the entire instruction list
