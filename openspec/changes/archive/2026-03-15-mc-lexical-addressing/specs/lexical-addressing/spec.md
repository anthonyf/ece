## MODIFIED Requirements

### Requirement: global environment retains named frames
The global environment frame SHALL use a hash-table frame (`(:hash-frame . <hash-table>)`). `define-variable!` and name-based `lookup-variable-value` SHALL continue to work unchanged on the global frame.

#### Scenario: Global define still works
- **WHEN** `(define x 42)` is evaluated at the top level
- **THEN** the global frame SHALL be updated using `define-variable!`
- **AND** `(lookup-variable-value 'x *global-env*)` SHALL return `42`
